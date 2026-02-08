//
//  WatchTimerManager.swift
//  Gym timer Watch App
//
//  Created by Gary yang on 2026/1/29.
//

import Foundation
import Combine
import SwiftUI
import WatchKit
import UserNotifications

// MARK: - Timer Phase (Watch)
enum WatchTimerPhase: String, CaseIterable {
    case idle = "Ready"
    case prepare = "Prepare"
    case train = "Train"
    case rest = "Rest"
    case waitingForTap = "Waiting"
    case completed = "Done"
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .prepare: return .orange
        case .train: return .green
        case .rest: return .blue
        case .waitingForTap: return .green
        case .completed: return .purple
        }
    }
    
    var systemImage: String {
        switch self {
        case .idle: return "play.circle.fill"
        case .prepare: return "figure.stand"
        case .train: return "figure.run"
        case .rest: return "pause.circle.fill"
        case .waitingForTap: return "hand.tap.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Timer Settings (Watch)
struct WatchTimerSettings: Codable {
    var sets: Int = 3
    var prepareSeconds: Int = 10
    var trainSeconds: Int = 45
    var restSeconds: Int = 30
    var restOnlyMode: Bool = false
    
    static let `default` = WatchTimerSettings()
}

// MARK: - Watch Timer Manager
class WatchTimerManager: ObservableObject {
    // Published properties
    @Published var settings: WatchTimerSettings {
        didSet {
            saveSettings()
        }
    }
    @Published var currentPhase: WatchTimerPhase = .idle
    @Published var currentSet: Int = 1
    @Published var remainingSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    
    // Private properties
    private var timer: Timer?
    private var backgroundDate: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // Singleton
    static let shared = WatchTimerManager()
    
    private init() {
        self.settings = Self.loadSettings()
        setupBackgroundHandling()
    }
    
    // MARK: - Settings Persistence
    private static func loadSettings() -> WatchTimerSettings {
        if let data = UserDefaults.standard.data(forKey: "WatchTimerSettings"),
           let settings = try? JSONDecoder().decode(WatchTimerSettings.self, from: data) {
            return settings
        }
        return .default
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "WatchTimerSettings")
        }
    }
    
    // MARK: - Background Handling
    private func setupBackgroundHandling() {
        NotificationCenter.default.publisher(for: WKExtension.applicationWillResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleWillResignActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleDidBecomeActive()
            }
            .store(in: &cancellables)
    }
    
    private func handleWillResignActive() {
        guard isRunning, !isPaused else { return }
        backgroundDate = Date()
        // Schedule local notification so user gets alerted when phase ends
        if remainingSeconds > 0 && currentPhase != .waitingForTap {
            WatchNotificationManager.shared.schedulePhaseCompleteNotification(
                in: remainingSeconds,
                phaseName: currentPhase.displayName
            )
        }
    }
    
    private func handleDidBecomeActive() {
        WatchNotificationManager.shared.cancelPhaseNotification()
        guard let bgDate = backgroundDate, isRunning, !isPaused else { return }
        
        let elapsedInBackground = Int(Date().timeIntervalSince(bgDate))
        backgroundDate = nil
        advanceTimer(by: elapsedInBackground)
    }
    
    // MARK: - Timer Control
    func start() {
        guard !isRunning else { return }
        WatchNotificationManager.shared.requestPermission()
        
        isRunning = true
        isPaused = false
        currentSet = 1
        
        if settings.prepareSeconds > 0 {
            transitionTo(phase: .prepare)
            startTimer()
        } else if settings.restOnlyMode {
            transitionTo(phase: .waitingForTap)
        } else {
            transitionTo(phase: .train)
            startTimer()
        }
        
        WatchWorkoutManager.shared.startWorkoutSession()
        playHaptic(.start)
    }
    
    func startRestTimer() {
        guard isRunning, currentPhase == .waitingForTap else { return }
        
        playHaptic(.success)
        transitionTo(phase: .rest)
        startTimer()
    }
    
    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        startTimer()
    }
    
    func stop() {
        WatchWorkoutManager.shared.endWorkoutSession()
        WatchNotificationManager.shared.cancelPhaseNotification()
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        currentPhase = .idle
        currentSet = 1
        remainingSeconds = 0
        playHaptic(.stop)
    }
    
    func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }
    
    // MARK: - Timer Logic
    private func startTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func tick() {
        guard remainingSeconds > 0 else {
            handlePhaseComplete()
            return
        }
        
        remainingSeconds -= 1
        
        // Countdown haptic for last 3 seconds
        if remainingSeconds <= 3 && remainingSeconds > 0 {
            playHaptic(.click)
        }
    }
    
    private func handlePhaseComplete() {
        playHaptic(.success)
        
        if settings.restOnlyMode {
            switch currentPhase {
            case .prepare:
                transitionTo(phase: .waitingForTap)
                timer?.invalidate()
                timer = nil
                
            case .rest:
                if currentSet >= settings.sets {
                    transitionTo(phase: .completed)
                    stop()
                } else {
                    currentSet += 1
                    transitionTo(phase: .waitingForTap)
                    timer?.invalidate()
                    timer = nil
                }
                
            default:
                break
            }
        } else {
            switch currentPhase {
            case .prepare:
                transitionTo(phase: .train)
                
            case .train:
                if currentSet >= settings.sets {
                    transitionTo(phase: .completed)
                    stop()
                } else {
                    transitionTo(phase: .rest)
                }
                
            case .rest:
                currentSet += 1
                transitionTo(phase: .train)
                
            default:
                break
            }
        }
    }
    
    private func transitionTo(phase: WatchTimerPhase) {
        currentPhase = phase
        
        switch phase {
        case .prepare:
            remainingSeconds = settings.prepareSeconds
        case .train:
            remainingSeconds = settings.trainSeconds
        case .rest:
            remainingSeconds = settings.restSeconds
        case .waitingForTap:
            remainingSeconds = 0
        default:
            remainingSeconds = 0
        }
    }
    
    // MARK: - Background Time Calculation
    private func advanceTimer(by seconds: Int) {
        var remaining = seconds
        
        while remaining > 0 && isRunning && currentPhase != .completed {
            if remaining >= remainingSeconds {
                remaining -= remainingSeconds
                remainingSeconds = 0
                handlePhaseComplete()
            } else {
                remainingSeconds -= remaining
                remaining = 0
            }
        }
    }
    
    // MARK: - Haptic Feedback
    private func playHaptic(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
    
    // MARK: - Formatted Time
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progressPercentage: Double {
        let totalForPhase: Int
        switch currentPhase {
        case .prepare: totalForPhase = settings.prepareSeconds
        case .train: totalForPhase = settings.trainSeconds
        case .rest: totalForPhase = settings.restSeconds
        default: return 0
        }
        
        guard totalForPhase > 0 else { return 0 }
        return Double(totalForPhase - remainingSeconds) / Double(totalForPhase)
    }
}
