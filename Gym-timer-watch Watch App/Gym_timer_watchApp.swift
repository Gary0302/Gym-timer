//
//  Gym_timer_WatchApp.swift
//  Gym timer Watch App
//
//  Created by Gary yang on 2026/1/29.
//

import SwiftUI

@main
struct Gym_timer_Watch_AppApp: App {
    init() {
        WatchNotificationManager.shared.requestPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}
