//
//  PointageView.swift
//  timesheetAppleWatch Watch App
//
//  Created by jonathan lemaine on 12/07/2024.
//

import SwiftUI
@available(iOS 14.0, *)
struct PointageView: View {
    @ObservedObject var model: TimeSheetModel
    
    var body: some View {
        VStack {
            Text(model.etatActuel)
                .font(.headline)
            
            if let dernierPointage = model.dernierPointage {
                Text(timeString(from: dernierPointage))
                    .font(.subheadline)
            }
            
            ProgressView(value: model.progression)
                .progressViewStyle(CircularProgressViewStyle())
                .frame(width: 100, height: 100)
            
            Button(action: model.actionPointage) {
                Text(boutonTexte())
                    .foregroundColor(.white)
                    .padding()
                    .background(boutonCouleur())
                    .cornerRadius(15)
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func boutonTexte() -> String {
        switch model.etatActuel {
        case "Non commencé": return "Commencer"
        case "Entrée": return "Pause"
        case "Pause": return "Reprise"
        case "Sortie": return "Reset"
        default: return "Stop"
        }
    }
    
    private func boutonCouleur() -> Color {
        switch model.etatActuel {
        case "Non commencé": return .blue
        case "Entrée": return Color(red: 0.21, green: 0.37, blue: 0.20)
        case "Pause": return Color(red: 0.51, green: 0.64, blue: 0.39)
        case "Sortie": return Color(red: 0.91, green: 0.83, blue: 0.50)
        default: return Color(red: 0.99, green: 0.61, blue: 0.39)
        }
    }
}

