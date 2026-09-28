import Foundation
import WatchConnectivity

/// Pont WatchConnectivity côté montre.
///
/// Protocole (miroir de `lib/services/watch_service.dart`) :
/// * montre → iPhone : `["action": "toggle"]`
/// * iPhone → montre : `["state": "Entrée", "lastUpdate": "<ISO8601>"]`,
///   en message direct ou en `applicationContext`.
///
/// Les deux canaux sont traités de la même façon : `applicationContext` est
/// celui qui survit à une montre éteinte, `sendMessage` celui qui donne un
/// retour immédiat quand l'iPhone est joignable.
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    /// État de pointage publié par l'iPhone.
    @Published private(set) var state: String = "Non commencé"

    /// Vrai entre l'envoi d'une demande et la réception du nouvel état. Sert à
    /// verrouiller le bouton pour éviter un double pointage sur double tap.
    @Published private(set) var isSending: Bool = false

    /// Message d'erreur transitoire à afficher sur la montre.
    @Published private(set) var errorMessage: String?

    /// L'iPhone est-il joignable ? Un pointage reste possible sans cela : la
    /// demande est alors mise en file par `transferUserInfo`.
    @Published private(set) var isReachable: Bool = false

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    private override init() {
        super.init()
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    // MARK: - Envoi

    /// Demande à l'iPhone d'enregistrer l'étape suivante.
    ///
    /// `sendMessage` est tenté d'abord (instantané). S'il échoue ou si l'iPhone
    /// n'est pas joignable, la demande passe par `transferUserInfo`, que le
    /// système met en file et livre au réveil de l'application iOS : un
    /// pointage n'est donc jamais perdu parce que le téléphone dormait.
    func requestPointage() {
        guard let session, session.activationState == .activated else {
            errorMessage = "Montre non connectée"
            return
        }

        isSending = true
        errorMessage = nil

        let payload: [String: Any] = [
            "action": "toggle",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { [weak self] error in
                // L'envoi direct a échoué : on retombe sur la file persistante
                // plutôt que de perdre le pointage.
                session.transferUserInfo(payload)
                DispatchQueue.main.async {
                    self?.errorMessage = "Envoi différé"
                    self?.isSending = false
                }
                NSLog("[Watch] sendMessage échoué, basculé en transferUserInfo: \(error.localizedDescription)")
            }
        } else {
            session.transferUserInfo(payload)
            errorMessage = "iPhone absent — pointage mis en file"
            isSending = false
        }

        // Garde-fou : si aucune réponse n'arrive, le bouton se déverrouille
        // au bout de 5 s plutôt que de rester bloqué.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if self?.isSending == true { self?.isSending = false }
        }
    }

    // MARK: - Réception

    private func apply(_ payload: [String: Any]) {
        guard let newState = payload["state"] as? String else { return }
        DispatchQueue.main.async {
            self.state = newState
            self.isSending = false
            self.errorMessage = nil
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error {
            NSLog("[Watch] Activation échouée: \(error.localizedDescription)")
        }
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
        // Le contexte déjà reçu porte le dernier état connu : l'appliquer au
        // lancement évite d'afficher « Non commencé » à tort.
        apply(session.receivedApplicationContext)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        apply(message)
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        apply(userInfo)
    }
}
