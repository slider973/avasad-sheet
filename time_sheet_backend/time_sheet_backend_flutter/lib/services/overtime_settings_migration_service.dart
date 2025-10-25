import 'package:shared_preferences/shared_preferences.dart';
import 'overtime_calculation_mode_service.dart';
import '../features/preference/presentation/widgets/overtime_calculation_mode_widget.dart';

/// Service pour migrer les anciens paramètres vers le nouveau système
class OvertimeSettingsMigrationService {
  static const String _migrationCompletedKey =
      'overtime_settings_migration_completed';
  static const String _oldOvertimeEnabledKey = 'overtime_enabled'; // Ancien nom
  static const String _oldDailyOvertimeKey =
      'daily_overtime_enabled'; // Ancien nom

  /// Instance singleton
  static final OvertimeSettingsMigrationService _instance =
      OvertimeSettingsMigrationService._internal();
  factory OvertimeSettingsMigrationService() => _instance;
  OvertimeSettingsMigrationService._internal();

  /// Vérifie si la migration a déjà été effectuée
  Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationCompletedKey) ?? false;
  }

  /// Effectue la migration des anciens paramètres
  Future<void> migrateOvertimeSettings() async {
    if (await isMigrationCompleted()) {
      return; // Migration déjà effectuée
    }

    final prefs = await SharedPreferences.getInstance();
    final modeService = OvertimeCalculationModeService();

    try {
      // Vérifier s'il y a des anciens paramètres à migrer
      final hasOldOvertimeEnabled = prefs.containsKey(_oldOvertimeEnabledKey);
      final hasOldDailyOvertime = prefs.containsKey(_oldDailyOvertimeKey);

      if (hasOldOvertimeEnabled || hasOldDailyOvertime) {
        // Migrer vers le nouveau système
        await _performMigration(prefs, modeService);
      } else {
        // Pas d'anciens paramètres, utiliser les valeurs par défaut
        await _setDefaultConfiguration(modeService);
      }

      // Marquer la migration comme terminée
      await prefs.setBool(_migrationCompletedKey, true);
    } catch (e) {
      // En cas d'erreur, utiliser les valeurs par défaut
      await _setDefaultConfiguration(modeService);
      await prefs.setBool(_migrationCompletedKey, true);
      rethrow;
    }
  }

  /// Effectue la migration proprement dite
  Future<void> _performMigration(
    SharedPreferences prefs,
    OvertimeCalculationModeService modeService,
  ) async {
    // Analyser les anciens paramètres pour déterminer le mode approprié
    // Utiliser une méthode sécurisée pour lire les booléens
    final oldOvertimeEnabled =
        _safeBoolRead(prefs, _oldOvertimeEnabledKey, true) ?? true;
    final oldDailyOvertimeEnabled =
        _safeBoolRead(prefs, _oldDailyOvertimeKey, true) ?? true;

    OvertimeCalculationMode newMode;

    if (oldDailyOvertimeEnabled) {
      // L'utilisateur avait activé les heures sup journalières
      // → Mode journalier (ancien comportement)
      newMode = OvertimeCalculationMode.daily;
    } else {
      // L'utilisateur avait désactivé les heures sup journalières
      // → Mode mensuel avec compensation (nouveau comportement plus équitable)
      newMode = OvertimeCalculationMode.monthlyWithCompensation;
    }

    // Appliquer le nouveau mode
    await modeService.setCalculationMode(newMode);

    // Nettoyer les anciens paramètres
    await prefs.remove(_oldOvertimeEnabledKey);
    await prefs.remove(_oldDailyOvertimeKey);
  }

  /// Configure les valeurs par défaut pour les nouveaux utilisateurs
  Future<void> _setDefaultConfiguration(
      OvertimeCalculationModeService modeService) async {
    // Pour les nouveaux utilisateurs, utiliser le mode journalier par défaut
    // pour maintenir la compatibilité avec l'ancien comportement
    await modeService.setCalculationMode(OvertimeCalculationMode.daily);
  }

  /// Force une nouvelle migration (utile pour les tests ou le debug)
  Future<void> resetMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationCompletedKey);
  }

  /// Obtient un rapport de migration pour le debug
  Future<MigrationReport> getMigrationReport() async {
    final prefs = await SharedPreferences.getInstance();
    final modeService = OvertimeCalculationModeService();

    return MigrationReport(
      migrationCompleted: await isMigrationCompleted(),
      currentMode: await modeService.getCurrentMode(),
      hasOldOvertimeEnabled: prefs.containsKey(_oldOvertimeEnabledKey),
      hasOldDailyOvertime: prefs.containsKey(_oldDailyOvertimeKey),
      oldOvertimeEnabledValue:
          _safeBoolRead(prefs, _oldOvertimeEnabledKey, null),
      oldDailyOvertimeValue: _safeBoolRead(prefs, _oldDailyOvertimeKey, null),
    );
  }

  /// Lecture sécurisée d'un booléen depuis SharedPreferences
  /// Gère les cas où la valeur stockée n'est pas un booléen
  bool? _safeBoolRead(SharedPreferences prefs, String key, bool? defaultValue) {
    try {
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      // En cas d'erreur de cast (valeur stockée n'est pas un booléen)
      // Supprimer la valeur corrompue et retourner la valeur par défaut
      prefs.remove(key);
      return defaultValue;
    }
  }
}

/// Rapport de migration pour le debug et les logs
class MigrationReport {
  final bool migrationCompleted;
  final OvertimeCalculationMode currentMode;
  final bool hasOldOvertimeEnabled;
  final bool hasOldDailyOvertime;
  final bool? oldOvertimeEnabledValue;
  final bool? oldDailyOvertimeValue;

  const MigrationReport({
    required this.migrationCompleted,
    required this.currentMode,
    required this.hasOldOvertimeEnabled,
    required this.hasOldDailyOvertime,
    this.oldOvertimeEnabledValue,
    this.oldDailyOvertimeValue,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Migration Report:');
    buffer.writeln('  Migration completed: $migrationCompleted');
    buffer.writeln('  Current mode: ${currentMode.displayName}');
    buffer.writeln('  Had old overtime enabled: $hasOldOvertimeEnabled');
    buffer.writeln('  Had old daily overtime: $hasOldDailyOvertime');

    if (oldOvertimeEnabledValue != null) {
      buffer.writeln('  Old overtime enabled value: $oldOvertimeEnabledValue');
    }

    if (oldDailyOvertimeValue != null) {
      buffer.writeln('  Old daily overtime value: $oldDailyOvertimeValue');
    }

    return buffer.toString();
  }
}

/// Extension pour faciliter l'utilisation du service de migration
extension OvertimeSettingsMigrationExtension
    on OvertimeSettingsMigrationService {
  /// Effectue la migration si nécessaire au démarrage de l'application
  Future<void> migrateIfNeeded() async {
    if (!await isMigrationCompleted()) {
      await migrateOvertimeSettings();
    }
  }
}
