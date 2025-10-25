import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/services/overtime_settings_migration_service.dart';
import 'package:time_sheet/features/preference/presentation/widgets/overtime_calculation_mode_widget.dart';

void main() {
  group('OvertimeSettingsMigrationService', () {
    late OvertimeSettingsMigrationService migrationService;

    setUp(() {
      migrationService = OvertimeSettingsMigrationService();
    });

    tearDown(() async {
      // Nettoyer les SharedPreferences après chaque test
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    group('Migration des anciens paramètres', () {
      test(
          'Migre vers le mode journalier quand les heures sup journalières étaient activées',
          () async {
        // Simuler les anciens paramètres
        SharedPreferences.setMockInitialValues({
          'overtime_enabled': true,
          'daily_overtime_enabled': true,
        });

        // Effectuer la migration
        await migrationService.migrateOvertimeSettings();

        // Vérifier le résultat
        final report = await migrationService.getMigrationReport();
        expect(report.migrationCompleted, isTrue);
        expect(report.currentMode, equals(OvertimeCalculationMode.daily));
        expect(report.hasOldOvertimeEnabled, isFalse); // Doit être nettoyé
        expect(report.hasOldDailyOvertime, isFalse); // Doit être nettoyé
      });

      test(
          'Migre vers le mode mensuel quand les heures sup journalières étaient désactivées',
          () async {
        // Simuler les anciens paramètres
        SharedPreferences.setMockInitialValues({
          'overtime_enabled': true,
          'daily_overtime_enabled': false,
        });

        // Effectuer la migration
        await migrationService.migrateOvertimeSettings();

        // Vérifier le résultat
        final report = await migrationService.getMigrationReport();
        expect(report.migrationCompleted, isTrue);
        expect(report.currentMode,
            equals(OvertimeCalculationMode.monthlyWithCompensation));
      });

      test('Utilise les valeurs par défaut pour les nouveaux utilisateurs',
          () async {
        // Pas d'anciens paramètres
        SharedPreferences.setMockInitialValues({});

        // Effectuer la migration
        await migrationService.migrateOvertimeSettings();

        // Vérifier le résultat
        final report = await migrationService.getMigrationReport();
        expect(report.migrationCompleted, isTrue);
        expect(report.currentMode,
            equals(OvertimeCalculationMode.daily)); // Mode par défaut
        expect(report.hasOldOvertimeEnabled, isFalse);
        expect(report.hasOldDailyOvertime, isFalse);
      });
    });

    group('Gestion des migrations multiples', () {
      test('Ne migre pas deux fois', () async {
        // Première migration
        SharedPreferences.setMockInitialValues({
          'daily_overtime_enabled': true,
        });

        await migrationService.migrateOvertimeSettings();
        expect(await migrationService.isMigrationCompleted(), isTrue);

        // Simuler de nouveaux anciens paramètres (ne devrait pas être pris en compte)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('daily_overtime_enabled', false);

        // Tenter une seconde migration
        await migrationService.migrateOvertimeSettings();

        // Le mode ne devrait pas avoir changé
        final report = await migrationService.getMigrationReport();
        expect(report.currentMode, equals(OvertimeCalculationMode.daily));
      });

      test('Permet de forcer une nouvelle migration', () async {
        // Première migration
        SharedPreferences.setMockInitialValues({
          'daily_overtime_enabled': true,
        });

        await migrationService.migrateOvertimeSettings();
        expect(await migrationService.isMigrationCompleted(), isTrue);

        // Réinitialiser la migration
        await migrationService.resetMigration();
        expect(await migrationService.isMigrationCompleted(), isFalse);

        // Changer les paramètres et migrer à nouveau
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('daily_overtime_enabled', false);

        await migrationService.migrateOvertimeSettings();

        // Le mode devrait avoir changé
        final report = await migrationService.getMigrationReport();
        expect(report.currentMode,
            equals(OvertimeCalculationMode.monthlyWithCompensation));
      });
    });

    group('Gestion des erreurs', () {
      test('Gère les erreurs gracieusement', () async {
        // Simuler une erreur en utilisant des valeurs invalides
        SharedPreferences.setMockInitialValues({
          'daily_overtime_enabled': 'invalid_value', // Type incorrect
        });

        // La migration ne devrait pas échouer
        await migrationService.migrateOvertimeSettings();

        // Devrait utiliser les valeurs par défaut
        final report = await migrationService.getMigrationReport();
        expect(report.migrationCompleted, isTrue);
        expect(report.currentMode, equals(OvertimeCalculationMode.daily));
      });
    });

    group('Rapport de migration', () {
      test('Génère un rapport détaillé', () async {
        // Configurer des anciens paramètres
        SharedPreferences.setMockInitialValues({
          'overtime_enabled': false,
          'daily_overtime_enabled': true,
        });

        // Effectuer la migration
        await migrationService.migrateOvertimeSettings();

        // Vérifier le rapport
        final report = await migrationService.getMigrationReport();
        expect(report.migrationCompleted, isTrue);
        expect(report.currentMode, equals(OvertimeCalculationMode.daily));
        expect(
            report.hasOldOvertimeEnabled, isFalse); // Nettoyé après migration
        expect(report.hasOldDailyOvertime, isFalse); // Nettoyé après migration

        // Vérifier le toString
        final reportString = report.toString();
        expect(reportString, contains('Migration Report:'));
        expect(reportString, contains('Migration completed: true'));
        expect(reportString, contains('Current mode: Calcul journalier'));
      });

      test('Rapport avant migration', () async {
        // Configurer des anciens paramètres sans migrer
        SharedPreferences.setMockInitialValues({
          'overtime_enabled': true,
          'daily_overtime_enabled': false,
        });

        // Obtenir le rapport avant migration
        final report = await migrationService.getMigrationReport();
        expect(report.migrationCompleted, isFalse);
        expect(report.hasOldOvertimeEnabled, isTrue);
        expect(report.hasOldDailyOvertime, isTrue);
        expect(report.oldOvertimeEnabledValue, isTrue);
        expect(report.oldDailyOvertimeValue, isFalse);
      });
    });

    group('Extension migrateIfNeeded', () {
      test('Migre seulement si nécessaire', () async {
        // Première fois - devrait migrer
        SharedPreferences.setMockInitialValues({
          'daily_overtime_enabled': true,
        });

        await migrationService.migrateIfNeeded();
        expect(await migrationService.isMigrationCompleted(), isTrue);

        // Deuxième fois - ne devrait pas migrer à nouveau
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('daily_overtime_enabled', false);

        await migrationService.migrateIfNeeded();

        // Le mode ne devrait pas avoir changé
        final report = await migrationService.getMigrationReport();
        expect(report.currentMode, equals(OvertimeCalculationMode.daily));
      });
    });

    group('Scénarios de migration complexes', () {
      test('Migration avec seulement overtime_enabled', () async {
        SharedPreferences.setMockInitialValues({
          'overtime_enabled': false,
          // Pas de daily_overtime_enabled
        });

        await migrationService.migrateOvertimeSettings();

        final report = await migrationService.getMigrationReport();
        expect(report.migrationCompleted, isTrue);
        // Devrait utiliser le mode par défaut car daily_overtime_enabled n'existe pas
        expect(report.currentMode, equals(OvertimeCalculationMode.daily));
      });

      test('Migration avec seulement daily_overtime_enabled', () async {
        SharedPreferences.setMockInitialValues({
          // Pas de overtime_enabled
          'daily_overtime_enabled': false,
        });

        await migrationService.migrateOvertimeSettings();

        final report = await migrationService.getMigrationReport();
        expect(report.migrationCompleted, isTrue);
        expect(report.currentMode,
            equals(OvertimeCalculationMode.monthlyWithCompensation));
      });
    });
  });
}
