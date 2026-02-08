//
//  WatchNotificationManager.swift
//  Gym timer Watch App
//
//  Handles local notifications when app goes to background during timer session.
//

import Foundation
import UserNotifications

class WatchNotificationManager {
    static let shared = WatchNotificationManager()
    private let identifier = "GymTimerPhaseComplete"
    
    private init() {}
    
    // MARK: - Permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    // MARK: - Schedule notification for phase completion
    func schedulePhaseCompleteNotification(in seconds: Int, phaseName: String) {
        guard seconds > 0 else { return }
        
        cancelPhaseNotification()
        
        let content = UNMutableNotificationContent()
        content.title = "Gym Timer"
        content.body = phaseMessage(for: phaseName)
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Watch notification schedule error: \(error.localizedDescription)")
            }
        }
    }
    
    private func phaseMessage(for phaseName: String) -> String {
        switch phaseName {
        case "Prepare": return "Prepare done! Time to train."
        case "Train": return "Train done! Time to rest."
        case "Rest": return "Rest over! Next set."
        default: return "Timer phase complete!"
        }
    }
    
    // MARK: - Cancel
    func cancelPhaseNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
