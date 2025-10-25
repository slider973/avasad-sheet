import '../features/preference/presentation/widgets/overtime_calculation_mode_widget.dart';

/// Service pour gérer le mode de calcul des heures supplémentaires
/// Le mode est maintenant fixé à mensuel avec compensation
class OvertimeCalculationModeService {
  /// Instance singleton
  static final OvertimeCalculationModeService _instance =
      OvertimeCalculationModeService._internal();
  factory OvertimeCalculationModeService() => _instance;
  OvertimeCalculationModeService._internal();

  /// Obtient le mode de calcul actuel
  Future<OvertimeCalculationMode> getCurrentMode() async {
    // Toujours retourner le mode mensuel par défaut
    return OvertimeCalculationMode.monthlyWithCompensation;
  }

  /// Définit le mode de calcul (toujours mensuel maintenant)
  Future<void> setCalculationMode(OvertimeCalculationMode mode) async {
    // Ne fait rien - le mode est toujours mensuel
  }

  /// Vérifie si le mode mensuel avec compensation est activé
  Future<bool> isMonthlyCompensationEnabled() async {
    // Toujours activé maintenant
    return true;
  }

  /// Réinitialise au mode par défaut
  Future<void> resetToDefault() async {
    // Le mode par défaut est maintenant toujours mensuel
  }
}
