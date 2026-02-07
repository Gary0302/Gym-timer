//
//  Gym_timerApp.swift
//  Gym timer
//
//  Created by Gary yang on 2026/1/29.
//

import SwiftUI
import UserNotifications

@main
struct Gym_timerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ThemeTransitionView {
                ContentView()
            }
            .environmentObject(themeManager)
        }
    }
}

// MARK: - Theme Transition View
struct ThemeTransitionView<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isTransitioning = false
    @State private var overlayOpacity: Double = 0
    
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
            
            // Transition overlay
            if isTransitioning {
                Color(themeManager.currentTheme == .dark ? .black : .white)
                    .ignoresSafeArea()
                    .opacity(overlayOpacity)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: themeManager.currentTheme) { oldValue, newValue in
            performTransition(from: oldValue, to: newValue)
        }
    }
    
    private func performTransition(from oldTheme: AppTheme, to newTheme: AppTheme) {
        // Determine overlay color based on transition direction
        isTransitioning = true
        
        // Fade in overlay
        withAnimation(.easeIn(duration: 0.15)) {
            overlayOpacity = 0.3
        }
        
        // Fade out overlay after theme change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.25)) {
                overlayOpacity = 0
            }
        }
        
        // Remove overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isTransitioning = false
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 設定通知代理
        UNUserNotificationCenter.current().delegate = self
        
        // 預先準備音訊
        AudioManager.shared.prepareAudio()
        
        return true
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // 當 App 在前景時收到通知，仍然顯示
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // 使用者點擊通知時的處理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
