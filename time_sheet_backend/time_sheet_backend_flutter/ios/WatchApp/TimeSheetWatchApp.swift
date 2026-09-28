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

    var body: some Scene {
        WindowGroup {
            PointageView()
                .environmentObject(connectivity)
        }
    }
}
