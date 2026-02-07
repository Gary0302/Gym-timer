//
//  ContentView.swift
//  Gym timer
//
//  Created by Gary yang on 2026/1/29.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var timerManager = TimerManager.shared
    
    var body: some View {
        TimerView(timerManager: timerManager)
    }
}

#Preview {
    ContentView()
}
