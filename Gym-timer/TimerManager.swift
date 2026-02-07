//
//  TimerManager.swift
//  Gym timer
//
//  Created by Gary yang on 2026/1/29.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Timer Phase
enum TimerPhase: String, CaseIterable {
    case idle = "準備開始"
    case prepare = "預備"
    case train = "訓練"
    case rest = "休息"
    case waitingForTap = "等待中"  // 休息專用模式：等待用戶完成動作
    case completed = "完成"
    
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
}

// MARK: - Timer Settings
struct TimerSettings: Codable {
    var sets: Int = 3
    var prepareSeconds: Int = 10
    var trainSeconds: Int = 45
    var restSeconds: Int = 30
    var restOnlyMode: Bool = false  // 休息專用模式（重訓用）
    
    static let `default` = TimerSettings()
    
    // 計算總時間
    var totalDuration: Int {
        if restOnlyMode {
            // 休息專用模式：只計算休息時間
            return prepareSeconds + (sets * restSeconds)
        } else {
            return prepareSeconds + (sets * trainSeconds) + ((sets - 1) * restSeconds)
        }
    }
}

// MARK: - Timer Manager
class TimerManager: ObservableObject {
    // Published properties
    @Published var settings: TimerSettings {
        didSet {
            saveSettings()
        }
    }
    @Published var currentPhase: TimerPhase = .idle
    @Published var currentSet: Int = 1
    @Published var remainingSeconds: Int = 0
    @Published var totalElapsedSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    
    // Private properties
    private var timer: Timer?
    private var backgroundDate: Date?
    private var phaseStartDate: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // Managers
    private let notificationManager = NotificationManager.shared
    private let audioManager = AudioManager.shared
    private let languageManager = LanguageManager.shared
    
    private var l10n: L10n {
        languageManager.l10n
    }
    
    // Singleton
    static let shared = TimerManager()
    
    private init() {
        self.settings = Self.loadSettings()
        setupNotifications()
    }
    
    // MARK: - Settings Persistence
    private static func loadSettings() -> TimerSettings {
        if let data = UserDefaults.standard.data(forKey: "TimerSettings"),
           let settings = try? JSONDecoder().decode(TimerSettings.self, from: data) {
            return settings
        }
        return .default
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "TimerSettings")
        }
    }
    
    // MARK: - App Lifecycle
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppWillResignActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)
    }
    
    private func handleAppWillResignActive() {
        guard isRunning, !isPaused else { return }
        backgroundDate = Date()
        scheduleAllNotifications()
    }
    
    private func handleAppDidBecomeActive() {
        guard let bgDate = backgroundDate, isRunning, !isPaused else { return }
        
        let elapsedInBackground = Int(Date().timeIntervalSince(bgDate))
        backgroundDate = nil
        
        // Cancel scheduled notifications
        notificationManager.cancelAllNotifications()
        
        // Calculate new state based on elapsed time
        advanceTimer(by: elapsedInBackground)
    }
    
    // MARK: - Timer Control
    func start() {
        guard !isRunning else { return }
        
        notificationManager.requestPermission()
        audioManager.prepareAudio()
        
        isRunning = true
        isPaused = false
        currentSet = 1
        totalElapsedSeconds = 0
        
        // Start with prepare phase, or skip if prepare time is 0
        if settings.prepareSeconds > 0 {
            transitionTo(phase: .prepare)
            startTimer()
        } else if settings.restOnlyMode {
            // Rest only mode: wait for user to finish their set
            transitionTo(phase: .waitingForTap)
            // Don't start timer - waiting for user tap
        } else {
            // Normal mode: go directly to train
            transitionTo(phase: .train)
            startTimer()
        }
    }
    
    // Called when user finishes their set in rest only mode
    func startRestTimer() {
        guard isRunning, currentPhase == .waitingForTap else { return }
        
        audioManager.playPhaseComplete()
        transitionTo(phase: .rest)
        startTimer()
    }
    
    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        timer?.invalidate()
        timer = nil
        notificationManager.cancelAllNotifications()
    }
    
    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        startTimer()
    }
    
    func stop() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        currentPhase = .idle
        currentSet = 1
        remainingSeconds = 0
        totalElapsedSeconds = 0
        notificationManager.cancelAllNotifications()
    }
    
    func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }
    
    // MARK: - Skip & Restart
    func skipToNextSection() {
        guard isRunning, currentPhase != .completed, currentPhase != .idle else { return }
        
        audioManager.playPhaseComplete()
        
        if settings.restOnlyMode {
            // 休息專用模式
            switch currentPhase {
            case .prepare:
                transitionTo(phase: .waitingForTap)
                timer?.invalidate()
                timer = nil
                
            case .waitingForTap:
                // Skip waiting, start rest immediately
                transitionTo(phase: .rest)
                startTimer()
                
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
            // 正常模式
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
        
        // Reschedule notifications if in background
        notificationManager.cancelAllNotifications()
        if !isPaused && currentPhase != .waitingForTap {
            scheduleAllNotifications()
        }
    }
    
    func restartCurrentSection() {
        guard isRunning, currentPhase != .completed, currentPhase != .idle, currentPhase != .waitingForTap else { return }
        
        // Reset the current phase timer
        switch currentPhase {
        case .prepare:
            remainingSeconds = settings.prepareSeconds
        case .train:
            remainingSeconds = settings.trainSeconds
        case .rest:
            remainingSeconds = settings.restSeconds
        default:
            break
        }
        
        phaseStartDate = Date()
        
        // Reschedule notifications
        notificationManager.cancelAllNotifications()
        if !isPaused {
            scheduleAllNotifications()
        }
    }
    
    // MARK: - Timer Logic
    private func startTimer() {
        timer?.invalidate()
        phaseStartDate = Date()
        
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
        totalElapsedSeconds += 1
        
        // 倒數 3, 2, 1 時播放提示音
        if remainingSeconds <= 3 && remainingSeconds > 0 {
            audioManager.playCountdownBeep()
        }
    }
    
    private func handlePhaseComplete() {
        audioManager.playPhaseComplete()
        
        if settings.restOnlyMode {
            // 休息專用模式
            switch currentPhase {
            case .prepare:
                // 預備結束，等待用戶完成動作
                transitionTo(phase: .waitingForTap)
                timer?.invalidate()
                timer = nil
                
            case .rest:
                if currentSet >= settings.sets {
                    // 所有組數完成
                    transitionTo(phase: .completed)
                    stop()
                } else {
                    // 等待用戶完成下一組動作
                    currentSet += 1
                    transitionTo(phase: .waitingForTap)
                    timer?.invalidate()
                    timer = nil
                }
                
            default:
                break
            }
        } else {
            // 正常模式
            switch currentPhase {
            case .prepare:
                // 預備結束，開始第一組訓練
                transitionTo(phase: .train)
                
            case .train:
                if currentSet >= settings.sets {
                    // 所有組數完成
                    transitionTo(phase: .completed)
                    stop()
                } else {
                    // 進入休息
                    transitionTo(phase: .rest)
                }
                
            case .rest:
                // 休息結束，開始下一組
                currentSet += 1
                transitionTo(phase: .train)
                
            default:
                break
            }
        }
    }
    
    private func transitionTo(phase: TimerPhase) {
        currentPhase = phase
        phaseStartDate = Date()
        
        switch phase {
        case .prepare:
            remainingSeconds = settings.prepareSeconds
        case .train:
            remainingSeconds = settings.trainSeconds
        case .rest:
            remainingSeconds = settings.restSeconds
        case .waitingForTap:
            remainingSeconds = 0  // No countdown, waiting for tap
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
                totalElapsedSeconds += remainingSeconds
                remainingSeconds = 0
                handlePhaseComplete()
            } else {
                remainingSeconds -= remaining
                totalElapsedSeconds += remaining
                remaining = 0
            }
        }
    }
    
    // MARK: - Schedule Notifications
    private func scheduleAllNotifications() {
        var timeOffset: TimeInterval = 0
        var tempSet = currentSet
        var tempPhase = currentPhase
        var tempRemaining = remainingSeconds
        
        // Schedule notification for current phase end
        timeOffset += TimeInterval(tempRemaining)
        scheduleNotification(at: timeOffset, for: tempPhase, set: tempSet, isEnd: true)
        
        if settings.restOnlyMode {
            // 休息專用模式
            while true {
                switch tempPhase {
                case .prepare:
                    tempPhase = .rest
                    tempRemaining = settings.restSeconds
                    
                case .rest:
                    if tempSet >= settings.sets {
                        notificationManager.scheduleNotification(
                            title: l10n.workoutComplete,
                            body: l10n.workoutCompleteBody(sets: settings.sets),
                            timeInterval: timeOffset
                        )
                        return
                    } else {
                        tempSet += 1
                        tempRemaining = settings.restSeconds
                    }
                    
                default:
                    return
                }
                
                timeOffset += TimeInterval(tempRemaining)
                scheduleNotification(at: timeOffset, for: tempPhase, set: tempSet, isEnd: true)
            }
        } else {
            // 正常模式
            while true {
                switch tempPhase {
                case .prepare:
                    tempPhase = .train
                    tempRemaining = settings.trainSeconds
                    
                case .train:
                    if tempSet >= settings.sets {
                        notificationManager.scheduleNotification(
                            title: l10n.workoutComplete,
                            body: l10n.workoutCompleteBody(sets: settings.sets),
                            timeInterval: timeOffset
                        )
                        return
                    } else {
                        tempPhase = .rest
                        tempRemaining = settings.restSeconds
                    }
                    
                case .rest:
                    tempSet += 1
                    tempPhase = .train
                    tempRemaining = settings.trainSeconds
                    
                default:
                    return
                }
                
                timeOffset += TimeInterval(tempRemaining)
                scheduleNotification(at: timeOffset, for: tempPhase, set: tempSet, isEnd: true)
            }
        }
    }
    
    private func scheduleNotification(at timeOffset: TimeInterval, for phase: TimerPhase, set: Int, isEnd: Bool) {
        let title: String
        let body: String
        
        switch phase {
        case .prepare:
            title = l10n.preparePhaseEnd
            body = l10n.startTraining
        case .train:
            title = l10n.trainTimeUp
            body = l10n.trainSetComplete(set: set)
        case .rest:
            title = l10n.restEnd
            body = l10n.startNextSet(set: set + 1)
        default:
            return
        }
        
        notificationManager.scheduleNotification(title: title, body: body, timeInterval: timeOffset)
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
