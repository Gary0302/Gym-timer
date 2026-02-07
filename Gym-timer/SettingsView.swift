//
//  SettingsView.swift
//  Gym timer
//
//  Created by Gary yang on 2026/1/29.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.requestReview) private var requestReview
    
    private var l10n: L10n {
        languageManager.l10n
    }
    
    // 獲取實際應該使用的 color scheme
    private var effectiveColorScheme: ColorScheme {
        themeManager.currentTheme.colorScheme ?? systemColorScheme
    }
    
    // URLs
    private let githubURL = URL(string: "https://github.com/Gary0302/Gym-timer")!
    private let coffeeURL = URL(string: "https://buymeacoffee.com/garyyang")!
    
    // Feedback email URL
    private var feedbackURL: URL {
        let email = "yanggary2388@gmail.com"
        let subject = l10n.feedbackSubject
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let iosVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        
        let body = """
        \(l10n.feedbackBody)
        \(l10n.deviceInfo)
        App: Gym Timer v\(appVersion) (\(buildNumber))
        iOS: \(iosVersion)
        Device: \(deviceModel)
        """
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        return URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)")!
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 模式設定
                Section {
                    Toggle(isOn: $timerManager.settings.restOnlyMode) {
                        Label(l10n.restOnlyMode, systemImage: "dumbbell")
                    }
                } header: {
                    Text(l10n.modeSettings)
                } footer: {
                    Text(l10n.restOnlyModeDescription)
                }
                
                // MARK: - 訓練設定
                Section {
                    Stepper(value: $timerManager.settings.sets, in: 1...50) {
                        HStack {
                            Label(l10n.sets, systemImage: "repeat")
                            Spacer()
                            Text("\(timerManager.settings.sets) \(l10n.setsUnit)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(l10n.trainingSettings)
                }
                
                // MARK: - 時間設定
                Section {
                    TimeSettingRow(
                        title: l10n.prepareTime,
                        icon: "figure.stand",
                        color: .orange,
                        seconds: $timerManager.settings.prepareSeconds,
                        l10n: l10n
                    )
                    
                    // 只在非休息專用模式顯示訓練時間
                    if !timerManager.settings.restOnlyMode {
                        TimeSettingRow(
                            title: l10n.trainTime,
                            icon: "figure.run",
                            color: .green,
                            seconds: $timerManager.settings.trainSeconds,
                            l10n: l10n
                        )
                    }
                    
                    TimeSettingRow(
                        title: l10n.restTime,
                        icon: "pause.circle",
                        color: .blue,
                        seconds: $timerManager.settings.restSeconds,
                        l10n: l10n
                    )
                } header: {
                    Text(l10n.timeSettings)
                } footer: {
                    let total = timerManager.settings.totalDuration
                    let minutes = total / 60
                    let seconds = total % 60
                    Text("\(l10n.totalDuration)：\(minutes) \(l10n.minutes) \(seconds) \(l10n.seconds)")
                }
                
                // MARK: - 音效設定
                Section {
                    Toggle(isOn: $audioManager.isSoundEnabled) {
                        Label(l10n.soundAlert, systemImage: "speaker.wave.2")
                    }
                    .onChange(of: audioManager.isSoundEnabled) { _, _ in
                        audioManager.saveSettings()
                    }
                    
                    Toggle(isOn: $audioManager.isVibrationEnabled) {
                        Label(l10n.vibrationAlert, systemImage: "iphone.radiowaves.left.and.right")
                    }
                    .onChange(of: audioManager.isVibrationEnabled) { _, _ in
                        audioManager.saveSettings()
                    }
                } header: {
                    Text(l10n.alertSettings)
                } footer: {
                    Text(l10n.soundNotInterrupt)
                }
                
                // MARK: - 快速預設
                Section {
                    if timerManager.settings.restOnlyMode {
                        // 休息專用模式預設
                        Button {
                            applyRestOnlyPreset(sets: 4, prepare: 5, rest: 60)
                        } label: {
                            PresetRow(
                                title: l10n.shortRest,
                                detail: "4 \(l10n.setsUnit) · 60\(l10n.seconds) \(l10n.phaseRest)",
                                color: .cyan
                            )
                        }
                        
                        Button {
                            applyRestOnlyPreset(sets: 4, prepare: 5, rest: 90)
                        } label: {
                            PresetRow(
                                title: l10n.standardRest,
                                detail: "4 \(l10n.setsUnit) · 90\(l10n.seconds) \(l10n.phaseRest)",
                                color: .blue
                            )
                        }
                        
                        Button {
                            applyRestOnlyPreset(sets: 5, prepare: 5, rest: 120)
                        } label: {
                            PresetRow(
                                title: l10n.longRest,
                                detail: "5 \(l10n.setsUnit) · 2\(l10n.minutes) \(l10n.phaseRest)",
                                color: .purple
                            )
                        }
                        
                        Button {
                            applyRestOnlyPreset(sets: 5, prepare: 10, rest: 180)
                        } label: {
                            PresetRow(
                                title: l10n.powerlifting,
                                detail: "5 \(l10n.setsUnit) · 3\(l10n.minutes) \(l10n.phaseRest)",
                                color: .red
                            )
                        }
                    } else {
                        // 正常模式預設
                        Button {
                            applyPreset(sets: 3, prepare: 10, train: 30, rest: 15)
                        } label: {
                            PresetRow(
                                title: l10n.hiitQuick,
                                detail: "3 \(l10n.setsUnit) · 30\(l10n.seconds) \(l10n.phaseTrain) · 15\(l10n.seconds) \(l10n.phaseRest)",
                                color: .red
                            )
                        }
                        
                        Button {
                            applyPreset(sets: 4, prepare: 10, train: 45, rest: 30)
                        } label: {
                            PresetRow(
                                title: l10n.standardTraining,
                                detail: "4 \(l10n.setsUnit) · 45\(l10n.seconds) \(l10n.phaseTrain) · 30\(l10n.seconds) \(l10n.phaseRest)",
                                color: .green
                            )
                        }
                        
                        Button {
                            applyPreset(sets: 5, prepare: 15, train: 60, rest: 45)
                        } label: {
                            PresetRow(
                                title: l10n.enduranceTraining,
                                detail: "5 \(l10n.setsUnit) · 60\(l10n.seconds) \(l10n.phaseTrain) · 45\(l10n.seconds) \(l10n.phaseRest)",
                                color: .blue
                            )
                        }
                        
                        Button {
                            applyPreset(sets: 8, prepare: 10, train: 20, rest: 10)
                        } label: {
                            PresetRow(
                                title: l10n.tabata,
                                detail: "8 \(l10n.setsUnit) · 20\(l10n.seconds) \(l10n.phaseTrain) · 10\(l10n.seconds) \(l10n.phaseRest)",
                                color: .orange
                            )
                        }
                    }
                } header: {
                    Text(l10n.quickPresets)
                }
                
                // MARK: - 語言設定
                Section {
                    Picker(l10n.languageSettings, selection: $languageManager.currentLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                } header: {
                    Text(l10n.languageSettings)
                }
                
                // MARK: - 主題設定
                Section {
                    Picker(l10n.themeSettings, selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(l10n.themeSettings)
                }
                
                // MARK: - 支持我們
                Section {
                    // Rate on App Store
                    Button {
                        requestReview()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n.rateApp)
                                    .foregroundColor(.primary)
                                Text(l10n.rateAppDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // GitHub Star
                    Link(destination: githubURL) {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(.purple)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n.starOnGitHub)
                                    .foregroundColor(.primary)
                                Text(l10n.openSource)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Buy Me a Coffee
                    Link(destination: coffeeURL) {
                        HStack {
                            Image(systemName: "cup.and.saucer.fill")
                                .foregroundColor(.orange)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n.buyMeACoffee)
                                    .foregroundColor(.primary)
                                Text(l10n.supportDevelopment)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Feedback
                    Link(destination: feedbackURL) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n.feedback)
                                    .foregroundColor(.primary)
                                Text(l10n.feedbackDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(l10n.supportUs)
                }
            }
            .navigationTitle(l10n.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(l10n.done) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(effectiveColorScheme)
    }
    
    private func applyPreset(sets: Int, prepare: Int, train: Int, rest: Int) {
        withAnimation {
            timerManager.settings.sets = sets
            timerManager.settings.prepareSeconds = prepare
            timerManager.settings.trainSeconds = train
            timerManager.settings.restSeconds = rest
        }
    }
    
    private func applyRestOnlyPreset(sets: Int, prepare: Int, rest: Int) {
        withAnimation {
            timerManager.settings.sets = sets
            timerManager.settings.prepareSeconds = prepare
            timerManager.settings.restSeconds = rest
        }
    }
}

// MARK: - Time Setting Row (tap to open sheet)
struct TimeSettingRow: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var seconds: Int
    let l10n: L10n
    
    @State private var showPicker = false
    
    private var minutes: Int {
        seconds / 60
    }
    
    private var remainingSeconds: Int {
        seconds % 60
    }
    
    private var displayTime: String {
        if minutes > 0 {
            return "\(minutes) \(l10n.minutes) \(remainingSeconds) \(l10n.seconds)"
        } else {
            return "\(remainingSeconds) \(l10n.seconds)"
        }
    }
    
    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(displayTime)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            TimePickerSheet(
                title: title,
                icon: icon,
                color: color,
                seconds: $seconds,
                l10n: l10n
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Time Picker Sheet
struct TimePickerSheet: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var seconds: Int
    let l10n: L10n
    
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0
    
    private var effectiveColorScheme: ColorScheme {
        themeManager.currentTheme.colorScheme ?? systemColorScheme
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header icon
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(color)
                    .padding(.top, 20)
                
                // Time display
                Text(String(format: "%02d:%02d", selectedMinutes, selectedSeconds))
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                
                // Picker
                HStack(spacing: 0) {
                    // Minutes
                    VStack(spacing: 4) {
                        Picker(l10n.minutes, selection: $selectedMinutes) {
                            ForEach(0..<60) { min in
                                Text("\(min)").tag(min)
                                    .font(.title2)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        
                        Text(l10n.minutes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(":")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 24)
                    
                    // Seconds
                    VStack(spacing: 4) {
                        Picker(l10n.seconds, selection: $selectedSeconds) {
                            ForEach(0..<60) { sec in
                                Text(String(format: "%02d", sec)).tag(sec)
                                    .font(.title2)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        
                        Text(l10n.seconds)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 180)
                
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(l10n.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(l10n.done) {
                        seconds = selectedMinutes * 60 + selectedSeconds
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                }
            }
        }
        .onAppear {
            selectedMinutes = seconds / 60
            selectedSeconds = seconds % 60
        }
        .preferredColorScheme(effectiveColorScheme)
    }
}

// MARK: - Preset Row
struct PresetRow: View {
    let title: String
    let detail: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color.gradient)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView(timerManager: TimerManager.shared)
}
