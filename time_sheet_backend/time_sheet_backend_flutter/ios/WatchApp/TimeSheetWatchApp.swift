import SwiftUI

/// Application watchOS « Planet Time sheet ».
///
/// Elle ne contient aucune logique métier : pointer se résume à demander à
/// l'iPhone d'enregistrer l'étape suivante. Les règles (heures
/// supplémentaires, anomalies, absences, synchronisation PowerSync) restent
/// côté application iOS, qui est la seule source de vérité.
@main
struct TimeSheetWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            PointageView()
                .environmentObject(connectivity)
        }
        // Un retour au premier plan est le moment où l'écran risque le plus
        // d'être périmé : la montre a pu dormir pendant que l'utilisateur
        // pointait depuis l'iPhone, et un contexte arrivé entre-temps n'a pas
        // forcément été appliqué.
        .onChange(of: scenePhase) { phase in
            if phase == .active { connectivity.resynchronize() }
        }
    }
}
