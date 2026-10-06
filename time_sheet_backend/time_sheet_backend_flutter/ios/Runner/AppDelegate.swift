import UIKit
import Flutter
import flutter_local_notifications
import native_geofence

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Cette ligne n'est plus nécessaire dans les versions récentes du plugin
    // FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
    //     GeneratedPluginRegistrant.register(with: registry)
    // }

    // ⚠️ ORDRE CRITIQUE : ce callback doit être posé AVANT
    // GeneratedPluginRegistrant.register ci-dessous. Le `register` de
    // native_geofence appelle `fatalError` si le callback est encore nil —
    // l'application plante alors au lancement, avant tout affichage.
    // L'isolate d'arrière-plan déclenché par un événement de zone s'en sert
    // pour enregistrer les plugins dont il a besoin.
    NativeGeofencePlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
                                                                                                                                                                                                                                          
