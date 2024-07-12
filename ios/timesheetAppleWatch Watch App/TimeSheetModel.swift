
//
//  TimeSheetModel.swift
//  timesheetwatch Watch App
//
//  Created by jonathan lemaine on 11/07/2024.
//

import SwiftUI
import WatchConnectivity
@available(iOS 14.0, *)
class TimeSheetModel: NSObject, ObservableObject {
    @Published var etatActuel: String = "Non commencé"
    @Published var dernierPointage: Date?
    @Published var progression: Double = 0.0
    
    private var session: WCSession
    override init() {
           self.session = WCSession.default
           super.init()
           session.delegate = self
           session.activate()
       }
    
    func actionPointage() {
        let maintenant = Date()
        dernierPointage = maintenant
        
        switch etatActuel {
        case "Non commencé":
            etatActuel = "Entrée"
            animerProgression(0.25)
            print("TimeSheetEnter")
            envoyerMessage(type: "TimeSheetEnter", heure: maintenant)
        case "Entrée":
            etatActuel = "Pause"
            animerProgression(0.5)
            envoyerMessage(type: "TimeSheetStartBreak", heure: maintenant)
        case "Pause":
            etatActuel = "Reprise"
            animerProgression(0.75)
            envoyerMessage(type: "TimeSheetEndBreak", heure: maintenant)
        case "Reprise":
            etatActuel = "Sortie"
            animerProgression(1.0)
            envoyerMessage(type: "TimeSheetOut", heure: maintenant)
        case "Sortie":
            etatActuel = "Non commencé"
            animerProgression(0.0)
            // Réinitialiser les données si nécessaire
        default:
            break
        }
    }
    @available(iOS 14.0, *)
    private func animerProgression(_ nouvelleValeur: Double) {
        if #available(iOS 14.0, *) {
            withAnimation(.easeInOut(duration: 0.5)) {
                progression = nouvelleValeur
            }
        }
        
    }
    
    private func envoyerMessage(type: String, heure: Date) {
        guard session.isReachable else {
            print("L'application iOS n'est pas accessible")
            return
        }
        
        let message = [
            "eventType": type,
            "timestamp": heure.timeIntervalSince1970
        ] as [String : Any]
        print("toto sendMessage")
        session.sendMessage(message, replyHandler: { response in
                print("Message envoyé avec succès. Réponse : \(response)")
            }) { error in
                print("Erreur lors de l'envoi du message : \(error.localizedDescription)")
                // Gérer l'erreur (par exemple, enregistrer localement pour réessayer plus tard)
            }
    }
}
@available(iOS 14.0, *)
extension TimeSheetModel: WCSessionDelegate {
#if os(iOS)
func sessionDidBecomeInactive(_ session: WCSession) {
    // Handle session becoming inactive (iOS only)
}

func sessionDidDeactivate(_ session: WCSession) {
    // Handle session deactivation (iOS only)
}
#endif
    
    
    // Implémentez toutes les méthodes nécessaires de WCSessionDelegate
       func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
           // Gestion de l'activation
       }


       func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
           // Gestion de la réception de message
           DispatchQueue.main.async {
               guard let method = message["method"] as? String else {
                   replyHandler(["error": "Invalid method"])
                   return
               }

               switch method {
               case "onMessageReceived":
                   // Mise à jour de l'état ou autres actions nécessaires
                   self.etatActuel = (message["data"] as? String) ?? "default"
                   replyHandler(["status": "success"])
               default:
                   replyHandler(["error": "Unknown method"])
               }
           }
       }
    
    
}
