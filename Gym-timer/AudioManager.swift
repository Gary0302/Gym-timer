//
//  AudioManager.swift
//  Gym timer
//
//  Created by Gary yang on 2026/1/29.
//

import Foundation
import UIKit
import AVFoundation
import AudioToolbox

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @Published var isSoundEnabled = true
    @Published var isVibrationEnabled = true
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Audio Session Setup
    func prepareAudio() {
        do {
            // 使用 ambient 類別，這樣不會中斷正在播放的音樂
            // 我們的提示音會與背景音樂混合播放
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sound Effects
    func playCountdownBeep() {
        guard isSoundEnabled else { return }
        
        // 使用系統音效 - 短促的提示音
        AudioServicesPlaySystemSound(1057) // Tink sound
        
        if isVibrationEnabled {
            // 輕微震動
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    func playPhaseComplete() {
        guard isSoundEnabled else {
            // 即使關閉聲音，也提供震動回饋
            if isVibrationEnabled {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            return
        }
        
        // 使用系統音效 - 階段完成的提示音
        AudioServicesPlaySystemSound(1025) // New Mail sound
        
        if isVibrationEnabled {
            // 明顯震動
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    func playWorkoutComplete() {
        guard isSoundEnabled else {
            if isVibrationEnabled {
                // 連續震動表示完成
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    generator.notificationOccurred(.success)
                }
            }
            return
        }
        
        // 播放完成音效
        AudioServicesPlaySystemSound(1026)
        
        if isVibrationEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    // MARK: - Settings Persistence
    private func loadSettings() {
        isSoundEnabled = UserDefaults.standard.object(forKey: "SoundEnabled") as? Bool ?? true
        isVibrationEnabled = UserDefaults.standard.object(forKey: "VibrationEnabled") as? Bool ?? true
    }
    
    func saveSettings() {
        UserDefaults.standard.set(isSoundEnabled, forKey: "SoundEnabled")
        UserDefaults.standard.set(isVibrationEnabled, forKey: "VibrationEnabled")
    }
    
    func toggleSound() {
        isSoundEnabled.toggle()
        saveSettings()
    }
    
    func toggleVibration() {
        isVibrationEnabled.toggle()
        saveSettings()
    }
}
