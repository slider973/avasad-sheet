/// Configuration des fonctionnalités du timer
///
/// Permet d'activer/désactiver les nouvelles fonctionnalités de manière propre
class TimerFeatureFlags {
  /// Active les nouvelles informations de temps de travail calculées
  static const bool enableEnhancedWorkTimeInfo = false;

  /// Active l'affichage de la durée en temps réel
  static const bool enableRealTimeDuration = false;

  /// Active l'affichage de l'heure de fin estimée
  static const bool enableEstimatedEndTime = false;

  /// Active l'affichage des heures supplémentaires
  static const bool enableOvertimeDisplay = false;

  /// Active l'utilisation du WorkTimeCalculatorService
  static const bool enableWorkTimeCalculatorService = false;

  /// Active les notifications améliorées avec informations détaillées
  static const bool enableEnhancedNotifications = false;
}
