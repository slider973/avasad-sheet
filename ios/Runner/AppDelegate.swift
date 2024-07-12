import UIKit
import Flutter
import WatchConnectivity

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
    var session: WCSession?
    
    // Fonction principale de l'application, appelée au lancement
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Enregistrement des plugins générés par Flutter
        GeneratedPluginRegistrant.register(with: self)
        
        // Initialisation du canal Flutter pour la communication
        initFlutterChannel()
        
        // Vérification de la prise en charge de la session de montre et activation si supportée
        if WCSession.isSupported() {
            print("Watch Session Supported")
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        
        // Appel de la méthode super pour terminer le lancement
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Initialisation du canal Flutter pour communiquer avec la montre
    private func initFlutterChannel() {
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "com.example.watchApp",
                binaryMessenger: controller.binaryMessenger)
            
            // Gestionnaire d'appel de méthode pour recevoir les messages de Flutter
            channel.setMethodCallHandler({ [weak self] (
                call: FlutterMethodCall,
                result: @escaping FlutterResult) -> Void in
                switch call.method {
                case "flutterToWatch":
                    print("flutterToWatch")
                    // Vérification de la disponibilité de la session de la montre et extraction des données
                    guard let watchSession = self?.session, watchSession.isPaired, watchSession.isReachable, let methodData = call.arguments as? [String: Any], let method = methodData["method"], let data = methodData["data"] else {
                        result(false)
                        return
                    }
                    
                    let watchData: [String: Any] = ["method": method, "data": data]
                    print(watchData)
                    // Envoi du message à la montre
                    watchSession.sendMessage(watchData) { (replyData) in
                        print("\(replyData)")
                    } errorHandler: { (err) in
                        print("\(err)")
                    }
                    result(true)
                default:
                    result(FlutterMethodNotImplemented)
                }
            })
        }
    }
    
    // Implémentez toutes les méthodes nécessaires de WCSessionDelegate
    
    // Appelée lorsque la session est activée
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WCSession activation succeeded with state: \(activationState.rawValue)")
    }
    
    // Appelée lorsque la session devient inactive
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession did become inactive")
    }
    
    // Appelée lorsque la session est désactivée
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession did deactivate")
        // Réactiver la session si nécessaire
        session.activate()
    }
    
    // Appelée lorsque l'application iOS reçoit un message de la montre
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let method = message["method"] as? String, let controller = self.window?.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(
                    name: "com.example.watchApp",
                    binaryMessenger: controller.binaryMessenger)
                // Transmet le message reçu à Flutter
                channel.invokeMethod(method, arguments: message)
            }
        }
    }

    // Implémentation des autres méthodes requises par WCSessionDelegate
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Received message from watch: \(message)")
        DispatchQueue.main.async {
            if let eventType = message["eventType"] as? String,
                       let timestamp = message["timestamp"] as? Double,
                       let controller = self.window?.rootViewController as? FlutterViewController {
                        
                        let channel = FlutterMethodChannel(
                            name: "com.example.watchApp",
                            binaryMessenger: controller.binaryMessenger)
                        
                        // Créez les arguments pour Flutter
                        let arguments: [String: Any] = ["eventType": eventType, "timestamp": timestamp]
                        
                        // Transmet le message reçu à Flutter avec la méthode "onMessageReceived"
                        channel.invokeMethod("onMessageReceived", arguments: arguments)
                        
                        // Répondre au message
                        replyHandler(["response": "Message received on iOS"])
                        print("methode: onMessageReceived, arguments: \(arguments)")
            }else {
            
                print("Method or eventType not found in message")
            }
            
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Received application context from watch: \(applicationContext)")
    }
    
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        if let error = error {
            print("User info transfer failed with error: \(error.localizedDescription)")
        } else {
            print("User info transfer succeeded")
        }
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("Received file from watch: \(file)")
    }
}
