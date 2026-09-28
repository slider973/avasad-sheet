import Foundation
import WatchConnectivity

/// Pont WatchConnectivity côté montre.
///
/// Protocole (miroir de `lib/services/watch_service.dart`) :
/// * montre → iPhone : `["action": "toggle", "requestId": "<UUID>",
///   "timestamp": "<ISO8601>"]`
/// * iPhone → montre : `["state": "Entrée", "lastUpdate": "<ISO8601>"]`
///
/// ⚠️ `transferUserInfo` n'est PAS utilisé, malgré son apparente pertinence :
/// le plugin Flutter `watch_connectivity` n'implémente pas
/// `session(_:didReceiveUserInfo:)` côté iOS. Une demande envoyée par ce canal
/// n'atteint jamais le code Dart — elle serait silencieusement perdue.
///
/// La demande part donc sur les deux canaux que le plugin sait recevoir :
/// * `sendMessage` — instantané, exige un iPhone joignable ;
/// * `updateApplicationContext` — persistant, livré au prochain réveil de
///   l'application iOS. C'est lui qui sauve le pointage quand le téléphone
///   dort.
///
/// Conséquence : une même demande peut arriver deux fois, et le contexte est
/// relu à chaque lancement de l'app iOS. D'où le `requestId`, sur lequel le
/// côté Dart déduplique — sans quoi chaque redémarrage rejouerait le dernier
/// pointage.
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

    // MARK: - Reconnexion

    /// À appeler chaque fois que l'app watch revient au premier plan.
    ///
    /// Trois choses peuvent avoir changé pendant la veille : la session a pu
    /// être désactivée, un contexte a pu arriver sans que la vue soit à
    /// l'écran, et l'utilisateur a pu pointer depuis l'iPhone. Sans cette
    /// resynchronisation, la montre affiche un état périmé et propose la
    /// mauvaise étape suivante.
    func resynchronize() {
        guard let session else { return }

        if session.activationState != .activated {
            session.activate()
            // `apply` sera fait par le callback d'activation.
            return
        }

        DispatchQueue.main.async { self.isReachable = session.isReachable }

        // Le contexte déjà reçu est la source la plus fiable hors ligne.
        apply(session.receivedApplicationContext)

        // Puis on demande l'état courant, au cas où l'iPhone ait enregistré un
        // pointage sans que le contexte ait été livré à la montre.
        guard session.isReachable else { return }
        session.sendMessage(["request": "state"], replyHandler: { [weak self] reply in
            self?.apply(reply)
        }, errorHandler: { error in
            NSLog("[Watch] Demande d'état échouée: \(error.localizedDescription)")
        })
    }

    // MARK: - Envoi

    /// Demande à l'iPhone d'enregistrer l'étape suivante.
    ///
    /// Le contexte d'application est écrit dans tous les cas : c'est le seul
    /// canal reçu par le plugin qui survive à un iPhone endormi. Un
    /// `sendMessage` s'y ajoute quand le téléphone est joignable, pour le
    /// retour immédiat. La déduplication par `requestId` côté Dart rend cette
    /// double émission sans danger.
    func requestPointage() {
        guard let session, session.activationState == .activated else {
            errorMessage = "Montre non connectée"
            return
        }

        isSending = true
        errorMessage = nil

        let payload: [String: Any] = [
            "action": "toggle",
            "requestId": UUID().uuidString,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]

        // Canal persistant d'abord : si l'application est tuée juste après,
        // la demande est déjà déposée.
        do {
            try session.updateApplicationContext(payload)
        } catch {
            NSLog("[Watch] updateApplicationContext échoué: \(error.localizedDescription)")
            errorMessage = "Pointage non transmis"
            isSending = false
            return
        }

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                // Pas de repli à tenter : le contexte est déjà déposé et sera
                // livré au réveil de l'application iOS.
                NSLog("[Watch] sendMessage échoué, le contexte prendra le relais: \(error.localizedDescription)")
            }
        } else {
            errorMessage = "iPhone absent — pointage enregistré au réveil"
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

        // Puis demander l'état à jour — le contexte peut dater.
        if session.isReachable {
            session.sendMessage(["request": "state"], replyHandler: { [weak self] reply in
                self?.apply(reply)
            }, errorHandler: { _ in })
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
        // L'iPhone vient de redevenir joignable : c'est le moment de rattraper
        // un état qui aurait changé pendant la coupure.
        if session.isReachable { resynchronize() }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        apply(message)
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

}
