import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:time_sheet/features/geofencing/data/services/day_mirror_store.dart';
import 'package:time_sheet/features/geofencing/domain/entities/attendance_decision.dart';

/// Notifications locales du pointage automatique.
///
/// Instancie son propre plugin : la classe est appelée depuis l'isolate
/// d'arrière-plan, où les singletons initialisés au démarrage de
/// l'application ne sont pas disponibles.
class GeofenceNotifier {
  static const int decisionNotificationId = 9100;
  static const int ambiguityNotificationId = 9101;

  static const String _channelId = 'geofencing_pointage';
  static const String _channelName = 'Pointage automatique';
  static const String _channelDescription =
      'Informe des pointages effectués automatiquement par géolocalisation.';

  final FlutterLocalNotificationsPlugin _plugin;

  GeofenceNotifier({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
  }

  NotificationDetails _details({List<AndroidNotificationAction>? actions}) {
    final android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      actions: actions,
    );
    const darwin = DarwinNotificationDetails(presentSound: false);
    return NotificationDetails(android: android, iOS: darwin);
  }

  /// Message informatif : le pointage est déjà fait, l'utilisateur peut
  /// corriger depuis l'application s'il le souhaite.
  String _messageFor(AttendanceDecision decision) {
    final heure = DayMirrorStore.formatTime(decision.at);
    return switch (decision.action) {
      AttendanceAction.clockIn => 'Arrivée pointée à $heure.',
      AttendanceAction.startBreak => 'Pause débutée à $heure.',
      AttendanceAction.endBreak => 'Reprise pointée à $heure.',
      AttendanceAction.clockOut => 'Sortie pointée à $heure.',
      AttendanceAction.reconcile =>
        'Sortie reconstituée à $heure, heure de votre départ du travail.',
      _ => '',
    };
  }

  Future<void> notifyDecision(AttendanceDecision decision) async {
    final message = _messageFor(decision);
    if (message.isEmpty) return;

    await _plugin.show(
      decisionNotificationId,
      'Pointage automatique',
      decision.needsUserConfirmation
          ? '$message À vérifier dans l\'application.'
          : message,
      _details(),
    );
  }

  /// Question posée quand l'utilisateur est revenu sans reprendre : il peut
  /// être en train de déjeuner sur place ou avoir repris sans pointer.
  Future<void> notifyAmbiguity() async {
    await _plugin.show(
      ambiguityNotificationId,
      'Vous êtes revenu, mais la reprise n\'est pas pointée',
      'Êtes-vous en pause déjeuner ou de retour au travail ?',
      _details(actions: const [
        AndroidNotificationAction('geofence_eating', 'Je mange'),
        AndroidNotificationAction('geofence_working', 'Je travaille'),
      ]),
    );
  }

  Future<void> cancelAmbiguity() =>
      _plugin.cancel(ambiguityNotificationId);
}
