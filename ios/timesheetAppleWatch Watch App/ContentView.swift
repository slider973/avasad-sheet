//
//  ContentView.swift
//  timesheetAppleWatch Watch App
//
//  Created by jonathan lemaine on 12/07/2024.
//

import SwiftUI
@available(iOS 14.0, *)
struct ContentView: View {
    @StateObject private var timeSheetModel = TimeSheetModel()
    var body: some View {
        VStack {
            PointageView(model: timeSheetModel)
        }
        .padding()
    }
}
