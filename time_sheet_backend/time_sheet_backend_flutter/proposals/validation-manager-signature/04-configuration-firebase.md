# Configuration Firebase - Notifications Push

## Vue d'ensemble

Firebase est utilisé principalement pour :
- **Firebase Cloud Messaging (FCM)** : Notifications push cross-platform
- **Firebase Analytics** : Tracking des interactions
- **Firebase Crashlytics** : Monitoring des erreurs (optionnel)

## Configuration initiale

### 1. Structure du projet Firebase

```
firebase-project/
├── android/
│   └── google-services.json
├── ios/
│   └── GoogleService-Info.plist
├── web/
│   └── firebase-config.js
└── firebase.json
```

### 2. Configuration Firebase (firebase.json)

```json
{
  "messaging": {
    "enabled": true
  },
  "analytics": {
    "enabled": true
  },
  "performance": {
    "enabled": false
  },
  "crashlytics": {
    "enabled": true
  }
}
```

### 3. Cloud Functions pour notifications

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Fonction déclenchée par Supabase webhook
exports.sendValidationNotification = functions.https.onRequest(async (req, res) => {
  try {
    const { managerId, validationId, employeeName, period } = req.body;
    
    // Récupérer le FCM token du manager depuis Supabase
    const managerToken = await getManagerFcmToken(managerId);
    
    if (!managerToken) {
      return res.status(404).json({ error: 'Manager FCM token not found' });
    }
    
    // Construire le message
    const message = {
      token: managerToken,
      notification: {
        title: 'Nouvelle timesheet à valider',
        body: `${employeeName} - Période ${period}`,
      },
      data: {
        type: 'validation_request',
        validation_id: validationId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'validations',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };
    
    // Envoyer la notification
    const response = await admin.messaging().send(message);
    
    // Logger pour analytics
    await logNotificationSent(managerId, validationId, response);
    
    res.status(200).json({ success: true, messageId: response });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ error: error.message });
  }
});

// Fonction pour gérer les tokens FCM
exports.updateFcmToken = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { token, platform } = data;
  
  // Mettre à jour dans Supabase
  await updateUserFcmToken(userId, token, platform);
  
  return { success: true };
});
```

## Configuration Flutter

### 1. Initialisation Firebase

```dart
// lib/services/firebase/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
  
  late FirebaseMessaging _messaging;
  late FirebaseAnalytics _analytics;
  
  Future<void> initialize() async {
    // Initialiser Firebase
    await Firebase.initializeApp();
    
    _messaging = FirebaseMessaging.instance;
    _analytics = FirebaseAnalytics.instance;
    
    // Configuration des permissions
    await _requestPermissions();
    
    // Configuration du handler de messages
    await _setupMessageHandlers();
    
    // Récupérer et sauvegarder le token FCM
    await _setupTokenRefresh();
  }
  
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // iOS: notifications complètes
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Notifications autorisées');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('Notifications provisoires (iOS)');
    } else {
      print('Notifications refusées');
    }
  }
  
  Future<void> _setupMessageHandlers() async {
    // Handler pour les messages en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });
    
    // Handler pour l'ouverture de l'app via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageTap(message);
    });
    
    // Handler pour les messages en background (top-level function)
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
    
    // Vérifier si l'app a été ouverte via une notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }
  
  Future<void> _setupTokenRefresh() async {
    // Récupérer le token initial
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToSupabase(token);
    }
    
    // Écouter les changements de token
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToSupabase(newToken);
    });
  }
  
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      await supabase
        .from('users')
        .update({
          'fcm_token': token,
          'fcm_updated_at': DateTime.now().toIso8601String(),
          'platform': Platform.isIOS ? 'ios' : 'android',
        })
        .eq('id', userId);
        
      // Analytics
      await _analytics.logEvent(
        name: 'fcm_token_updated',
        parameters: {
          'platform': Platform.operatingSystem,
        },
      );
    } catch (e) {
      print('Erreur sauvegarde token FCM: $e');
    }
  }
}

// Handler pour messages en background (doit être top-level)
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  // Traiter le message en background
  if (message.data['type'] == 'validation_request') {
    // Sauvegarder localement pour affichage ultérieur
    await LocalNotificationService.instance.saveBackgroundNotification(message);
  }
}
```

### 2. Service de notifications locales

```dart
// lib/services/notifications/local_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final LocalNotificationService instance = LocalNotificationService._();
  LocalNotificationService._();
  
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    // Configuration Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuration iOS
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );
    
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Créer les canaux Android
    await _createNotificationChannels();
  }
  
  Future<void> _createNotificationChannels() async {
    const validationChannel = AndroidNotificationChannel(
      'validations',
      'Validations de timesheet',
      description: 'Notifications pour les validations de timesheet',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    
    const feedbackChannel = AndroidNotificationChannel(
      'feedback',
      'Retours et corrections',
      description: 'Notifications pour les retours sur les timesheets',
      importance: Importance.high,
      playSound: true,
    );
    
    await _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(validationChannel);
      
    await _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(feedbackChannel);
  }
  
  Future<void> showValidationNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'validations',
      'Validations de timesheet',
      channelDescription: 'Notifications pour les validations',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Nouvelle validation',
      styleInformation: BigTextStyleInformation(''),
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: jsonEncode(payload),
    );
  }
}
```

### 3. Configuration des topics

```dart
// lib/services/firebase/topic_manager.dart
class TopicManager {
  static const String TOPIC_MANAGERS = 'managers';
  static const String TOPIC_EMPLOYEES = 'employees';
  
  static Future<void> subscribeToRoleTopics(String role) async {
    final messaging = FirebaseMessaging.instance;
    
    if (role == 'manager') {
      await messaging.subscribeToTopic(TOPIC_MANAGERS);
      await messaging.unsubscribeFromTopic(TOPIC_EMPLOYEES);
    } else if (role == 'employee') {
      await messaging.subscribeToTopic(TOPIC_EMPLOYEES);
      await messaging.unsubscribeFromTopic(TOPIC_MANAGERS);
    }
    
    // Topic spécifique à l'organisation
    final orgId = await _getOrganizationId();
    if (orgId != null) {
      await messaging.subscribeToTopic('org_$orgId');
    }
  }
  
  static Future<void> subscribeToValidationUpdates(String validationId) async {
    await FirebaseMessaging.instance.subscribeToTopic('validation_$validationId');
  }
}
```

## Configuration Analytics

### 1. Events tracking

```dart
// lib/services/analytics/validation_analytics.dart
class ValidationAnalytics {
  final FirebaseAnalytics _analytics;
  
  ValidationAnalytics(this._analytics);
  
  // Track soumission
  Future<void> trackSubmission({
    required String employeeId,
    required String managerId,
    required int month,
    required int year,
  }) async {
    await _analytics.logEvent(
      name: 'timesheet_submitted',
      parameters: {
        'employee_id': employeeId,
        'manager_id': managerId,
        'period': '$month-$year',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  // Track validation
  Future<void> trackValidation({
    required String validationId,
    required String managerId,
    required Duration validationTime,
  }) async {
    await _analytics.logEvent(
      name: 'timesheet_validated',
      parameters: {
        'validation_id': validationId,
        'manager_id': managerId,
        'validation_time_hours': validationTime.inHours,
        'validation_time_minutes': validationTime.inMinutes,
      },
    );
  }
  
  // Track erreurs
  Future<void> trackError({
    required String validationId,
    required int errorCount,
    required String errorType,
  }) async {
    await _analytics.logEvent(
      name: 'validation_error',
      parameters: {
        'validation_id': validationId,
        'error_count': errorCount,
        'error_type': errorType,
      },
    );
  }
}
```

### 2. User properties

```dart
// Définir les propriétés utilisateur
Future<void> setUserProperties(User user) async {
  await FirebaseAnalytics.instance.setUserId(id: user.id);
  
  await FirebaseAnalytics.instance.setUserProperty(
    name: 'organization_id',
    value: user.organizationId,
  );
  
  await FirebaseAnalytics.instance.setUserProperty(
    name: 'user_role',
    value: user.role,
  );
  
  await FirebaseAnalytics.instance.setUserProperty(
    name: 'platform',
    value: Platform.operatingSystem,
  );
}
```

## Configuration des environnements

### 1. Environnement de développement

```dart
// lib/config/firebase_config_dev.dart
class FirebaseConfigDev {
  static const Map<String, dynamic> androidConfig = {
    'apiKey': 'AIza...-dev',
    'appId': '1:123...:android:...-dev',
    'messagingSenderId': '123456789-dev',
    'projectId': 'timesheet-dev',
  };
  
  static const Map<String, dynamic> iosConfig = {
    'apiKey': 'AIza...-dev',
    'appId': '1:123...:ios:...-dev',
    'messagingSenderId': '123456789-dev',
    'projectId': 'timesheet-dev',
    'iosBundleId': 'com.company.timesheet.dev',
  };
}
```

### 2. Environnement de production

```dart
// lib/config/firebase_config_prod.dart
class FirebaseConfigProd {
  static const Map<String, dynamic> androidConfig = {
    'apiKey': 'AIza...-prod',
    'appId': '1:123...:android:...-prod',
    'messagingSenderId': '123456789-prod',
    'projectId': 'timesheet-prod',
  };
  
  static const Map<String, dynamic> iosConfig = {
    'apiKey': 'AIza...-prod',
    'appId': '1:123...:ios:...-prod',
    'messagingSenderId': '123456789-prod',
    'projectId': 'timesheet-prod',
    'iosBundleId': 'com.company.timesheet',
  };
}
```

## Règles de sécurité Firebase

### 1. Cloud Messaging

```json
{
  "rules": {
    "fcm": {
      "tokens": {
        "$uid": {
          ".read": "$uid === auth.uid",
          ".write": "$uid === auth.uid"
        }
      }
    }
  }
}
```

### 2. Remote Config

```json
{
  "conditions": [
    {
      "name": "Managers",
      "expression": "device.customProperties['user_role'] == 'manager'"
    },
    {
      "name": "Employees",
      "expression": "device.customProperties['user_role'] == 'employee'"
    }
  ],
  "parameters": {
    "validation_timeout_hours": {
      "defaultValue": {
        "value": "48"
      },
      "conditionalValues": {
        "Managers": {
          "value": "72"
        }
      }
    },
    "max_pdf_size_mb": {
      "defaultValue": {
        "value": "10"
      }
    }
  }
}
```

## Monitoring et alertes

### 1. Cloud Functions monitoring

```javascript
// Alertes pour échecs de notifications
exports.monitorNotificationFailures = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const failedNotifications = await getFailedNotifications();
    
    if (failedNotifications.length > 10) {
      await sendAlertEmail({
        to: 'admin@company.com',
        subject: 'Alerte: Échecs de notifications',
        body: `${failedNotifications.length} notifications ont échoué`,
      });
    }
  });
```

### 2. Dashboard de suivi

```dart
// Widget pour afficher les stats Firebase
class NotificationStatsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NotificationStats>(
      stream: _getNotificationStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final stats = snapshot.data!;
        return Card(
          child: Column(
            children: [
              Text('Notifications envoyées: ${stats.sent}'),
              Text('Taux de livraison: ${stats.deliveryRate}%'),
              Text('Temps moyen: ${stats.avgDeliveryTime}s'),
            ],
          ),
        );
      },
    );
  }
}
```