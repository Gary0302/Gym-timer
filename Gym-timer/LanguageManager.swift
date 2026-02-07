//
//  LanguageManager.swift
//  Gym timer
//
//  Created by Gary yang on 2026/1/29.
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Codable {
    case chinese = "zh"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .chinese: return "繁體中文"
        case .english: return "English"
        }
    }
}

// MARK: - Localized Strings
struct L10n {
    let language: AppLanguage
    
    // App Title
    var appTitle: String {
        language == .chinese ? "健身計時器" : "Gym Timer"
    }
    
    // Timer Phases
    var phaseIdle: String {
        language == .chinese ? "準備開始" : "Ready"
    }
    
    var phasePrepare: String {
        language == .chinese ? "預備" : "Prepare"
    }
    
    var phaseTrain: String {
        language == .chinese ? "訓練" : "Train"
    }
    
    var phaseRest: String {
        language == .chinese ? "休息" : "Rest"
    }
    
    var phaseCompleted: String {
        language == .chinese ? "完成" : "Completed"
    }
    
    var phaseWaitingForTap: String {
        language == .chinese ? "做完請點擊" : "Tap when done"
    }
    
    func phaseName(for phase: TimerPhase) -> String {
        switch phase {
        case .idle: return phaseIdle
        case .prepare: return phasePrepare
        case .train: return phaseTrain
        case .rest: return phaseRest
        case .waitingForTap: return phaseWaitingForTap
        case .completed: return phaseCompleted
        }
    }
    
    // Buttons
    var start: String {
        language == .chinese ? "開始" : "Start"
    }
    
    var pause: String {
        language == .chinese ? "暫停" : "Pause"
    }
    
    var resume: String {
        language == .chinese ? "繼續" : "Resume"
    }
    
    var stop: String {
        language == .chinese ? "停止" : "Stop"
    }
    
    var cancel: String {
        language == .chinese ? "取消" : "Cancel"
    }
    
    var nextSection: String {
        language == .chinese ? "下一階段" : "Next"
    }
    
    var restartSection: String {
        language == .chinese ? "重新開始" : "Restart"
    }
    
    // Settings
    var settings: String {
        language == .chinese ? "設定" : "Settings"
    }
    
    var done: String {
        language == .chinese ? "完成" : "Done"
    }
    
    var trainingSettings: String {
        language == .chinese ? "訓練設定" : "Training Settings"
    }
    
    var sets: String {
        language == .chinese ? "組數" : "Sets"
    }
    
    var setsUnit: String {
        language == .chinese ? "組" : "sets"
    }
    
    var restOnlyMode: String {
        language == .chinese ? "休息專用模式" : "Rest Only Mode"
    }
    
    var restOnlyModeDescription: String {
        language == .chinese ? "重訓用，只計算組間休息時間" : "For weight training, only counts rest time between sets"
    }
    
    var modeSettings: String {
        language == .chinese ? "模式設定" : "Mode Settings"
    }
    
    var themeSettings: String {
        language == .chinese ? "外觀主題" : "Theme"
    }
    
    // Support Section
    var supportUs: String {
        language == .chinese ? "支持我們" : "Support Us"
    }
    
    var rateApp: String {
        language == .chinese ? "給個 5 星好評" : "Rate 5 Stars"
    }
    
    var rateAppDescription: String {
        language == .chinese ? "我們是永遠免費的，給個5星支持一下吧" : "We're free forever, please support us with 5 stars!"
    }
    
    var starOnGitHub: String {
        language == .chinese ? "GitHub 給星星" : "Star on GitHub"
    }
    
    var openSource: String {
        language == .chinese ? "給這個 App 一個星星吧" : "Give this app a star!"
    }
    
    var buyMeACoffee: String {
        language == .chinese ? "請我喝杯咖啡嗎？" : "Buy Me a Coffee?"
    }
    
    var supportDevelopment: String {
        language == .chinese ? "支持開發者繼續更新" : "Support continued development"
    }
    
    var feedback: String {
        language == .chinese ? "意見反饋" : "Feedback"
    }
    
    var feedbackDescription: String {
        language == .chinese ? "有問題或建議？告訴我們！" : "Have issues or suggestions? Let us know!"
    }
    
    var feedbackSubject: String {
        language == .chinese ? "Gym Timer 意見反饋" : "Gym Timer Feedback"
    }
    
    var feedbackBody: String {
        language == .chinese ? "請在下方寫下您的意見或建議：\n\n\n" : "Please write your feedback below:\n\n\n"
    }
    
    var deviceInfo: String {
        language == .chinese ? "--- 裝置資訊（請勿刪除）---" : "--- Device Info (please don't delete) ---"
    }
    
    var timeSettings: String {
        language == .chinese ? "時間設定" : "Time Settings"
    }
    
    var prepareTime: String {
        language == .chinese ? "預備時間" : "Prepare Time"
    }
    
    var trainTime: String {
        language == .chinese ? "訓練時間" : "Train Time"
    }
    
    var restTime: String {
        language == .chinese ? "休息時間" : "Rest Time"
    }
    
    var minutes: String {
        language == .chinese ? "分" : "min"
    }
    
    var seconds: String {
        language == .chinese ? "秒" : "sec"
    }
    
    var totalDuration: String {
        language == .chinese ? "總訓練時長" : "Total Duration"
    }
    
    var alertSettings: String {
        language == .chinese ? "提示設定" : "Alert Settings"
    }
    
    var soundAlert: String {
        language == .chinese ? "音效提示" : "Sound Alert"
    }
    
    var vibrationAlert: String {
        language == .chinese ? "震動提示" : "Vibration Alert"
    }
    
    var soundNotInterrupt: String {
        language == .chinese ? "音效使用環境音模式，不會中斷你的音樂" : "Sound uses ambient mode, won't interrupt your music"
    }
    
    var quickPresets: String {
        language == .chinese ? "快速預設" : "Quick Presets"
    }
    
    var hiitQuick: String {
        language == .chinese ? "HIIT 快速" : "HIIT Quick"
    }
    
    var standardTraining: String {
        language == .chinese ? "標準訓練" : "Standard"
    }
    
    var enduranceTraining: String {
        language == .chinese ? "耐力訓練" : "Endurance"
    }
    
    var tabata: String {
        language == .chinese ? "Tabata" : "Tabata"
    }
    
    // Rest Only Mode Presets
    var shortRest: String {
        language == .chinese ? "短休息" : "Short Rest"
    }
    
    var standardRest: String {
        language == .chinese ? "標準休息" : "Standard Rest"
    }
    
    var longRest: String {
        language == .chinese ? "長休息" : "Long Rest"
    }
    
    var powerlifting: String {
        language == .chinese ? "力量訓練" : "Powerlifting"
    }
    
    // Progress
    var progress: String {
        language == .chinese ? "進度" : "Progress"
    }
    
    func setProgress(current: Int, total: Int) -> String {
        language == .chinese ? "第 \(current) / \(total) 組" : "Set \(current) / \(total)"
    }
    
    // Language
    var languageSettings: String {
        language == .chinese ? "語言設定" : "Language"
    }
    
    // Notifications
    var workoutComplete: String {
        language == .chinese ? "🎉 訓練完成！" : "🎉 Workout Complete!"
    }
    
    func workoutCompleteBody(sets: Int) -> String {
        language == .chinese ? "太棒了！你完成了所有 \(sets) 組訓練！" : "Great job! You completed all \(sets) sets!"
    }
    
    var preparePhaseEnd: String {
        language == .chinese ? "⏱️ 預備階段結束" : "⏱️ Prepare Phase End"
    }
    
    var startTraining: String {
        language == .chinese ? "準備開始訓練！" : "Get ready to train!"
    }
    
    var trainTimeUp: String {
        language == .chinese ? "💪 訓練時間到！" : "💪 Train Time Up!"
    }
    
    func trainSetComplete(set: Int) -> String {
        language == .chinese ? "第 \(set) 組訓練結束，準備休息" : "Set \(set) complete, time to rest"
    }
    
    var restEnd: String {
        language == .chinese ? "⏰ 休息結束" : "⏰ Rest End"
    }
    
    func startNextSet(set: Int) -> String {
        language == .chinese ? "準備開始第 \(set) 組訓練！" : "Get ready for set \(set)!"
    }
}

// MARK: - Language Manager
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            saveLanguage()
        }
    }
    
    var l10n: L10n {
        L10n(language: currentLanguage)
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "AppLanguage"),
           let language = AppLanguage(rawValue: saved) {
            self.currentLanguage = language
        } else {
            // Default to Chinese
            self.currentLanguage = .chinese
        }
    }
    
    private func saveLanguage() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
    }
    
    func toggleLanguage() {
        currentLanguage = currentLanguage == .chinese ? .english : .chinese
    }
}

// MARK: - Theme
enum AppTheme: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return LanguageManager.shared.currentLanguage == .chinese ? "跟隨系統" : "System"
        case .light: return LanguageManager.shared.currentLanguage == .chinese ? "淺色" : "Light"
        case .dark: return LanguageManager.shared.currentLanguage == .chinese ? "深色" : "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            saveTheme()
        }
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "AppTheme"),
           let theme = AppTheme(rawValue: saved) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "AppTheme")
    }
}
