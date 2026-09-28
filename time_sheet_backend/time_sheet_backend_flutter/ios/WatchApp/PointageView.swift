import SwiftUI

/// Écran unique de la montre : l'état de la journée et un bouton qui pointe
/// l'étape suivante.
///
/// Le libellé du bouton est dérivé de l'état publié par l'iPhone, en suivant
/// exactement la même progression que l'application
/// (`TimesheetEntry.currentState` : Non commencé → Entrée → Pause → Reprise →
/// Sortie). La montre n'invente donc jamais une étape.
struct PointageView: View {
    @EnvironmentObject private var connectivity: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 8) {
            Text(connectivity.state)
                .font(.headline)
                .foregroundStyle(stateColor)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(2)

            if let next = nextStepLabel {
                Button(action: connectivity.requestPointage) {
                    HStack(spacing: 6) {
                        if connectivity.isSending {
                            ProgressView()
                        } else {
                            Image(systemName: nextStepIcon)
                        }
                        Text(next)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(stateColor)
                .disabled(connectivity.isSending)
            } else {
                // Journée terminée : plus rien à pointer. Proposer un bouton
                // inerte serait trompeur.
                Label("Journée terminée", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.green)
            }

            if let error = connectivity.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            } else if !connectivity.isReachable {
                Label("iPhone hors de portée", systemImage: "iphone.slash")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .navigationTitle("Pointage")
    }

    /// Libellé de l'étape suivante, `nil` quand la journée est terminée.
    private var nextStepLabel: String? {
        switch connectivity.state {
        case "Non commencé": return "Commencer"
        case "Entrée": return "Pause"
        case "Pause": return "Reprise"
        case "Reprise": return "Sortie"
        case "Sortie": return nil
        default: return "Pointer"
        }
    }

    private var nextStepIcon: String {
        switch connectivity.state {
        case "Non commencé": return "play.fill"
        case "Entrée": return "pause.fill"
        case "Pause": return "play.fill"
        case "Reprise": return "stop.fill"
        default: return "clock"
        }
    }

    /// Couleurs reprises du chronomètre de l'application iOS pour que les deux
    /// écrans se lisent de la même façon.
    private var stateColor: Color {
        switch connectivity.state {
        case "Entrée": return .teal
        case "Pause": return Color(red: 0.91, green: 0.83, blue: 0.50)
        case "Reprise": return Color(red: 0.99, green: 0.61, blue: 0.39)
        case "Sortie": return .green
        default: return .gray
        }
    }
}

#Preview {
    PointageView()
        .environmentObject(WatchConnectivityManager.shared)
}
