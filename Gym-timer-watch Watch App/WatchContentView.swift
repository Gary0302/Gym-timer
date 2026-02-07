//
//  WatchContentView.swift
//  Gym timer Watch App
//
//  Created by Gary yang on 2026/1/29.
//

import SwiftUI

struct WatchContentView: View {
    @StateObject private var timerManager = WatchTimerManager.shared
    
    var body: some View {
        TabView {
            // Timer View
            WatchTimerView()
                .environmentObject(timerManager)
            
            // Settings View
            WatchSettingsView()
                .environmentObject(timerManager)
        }
        .tabViewStyle(.verticalPage)
    }
}

// MARK: - Watch Timer View
struct WatchTimerView: View {
    @EnvironmentObject var timerManager: WatchTimerManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Phase indicator
            HStack(spacing: 4) {
                Image(systemName: timerManager.currentPhase.systemImage)
                    .foregroundColor(timerManager.currentPhase.color)
                Text(timerManager.currentPhase.displayName)
                    .font(.caption)
                    .foregroundColor(timerManager.currentPhase.color)
            }
            
            // Set Progress
            if timerManager.isRunning {
                Text("\(timerManager.currentSet)/\(timerManager.settings.sets)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Timer Display
            ZStack {
                // Progress Ring
                Circle()
                    .stroke(timerManager.currentPhase.color.opacity(0.3), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: timerManager.progressPercentage)
                    .stroke(
                        timerManager.currentPhase.color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timerManager.progressPercentage)
                
                // Time or Message
                if timerManager.currentPhase == .waitingForTap {
                    VStack(spacing: 2) {
                        Image(systemName: "hand.tap.fill")
                            .font(.title2)
                        Text("Tap")
                            .font(.caption2)
                    }
                    .foregroundColor(timerManager.currentPhase.color)
                } else {
                    Text(timerManager.formattedTime)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(width: 100, height: 100)
            
            // Control Buttons
            controlButtons
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var controlButtons: some View {
        if timerManager.currentPhase == .waitingForTap {
            // Done button for rest-only mode
            Button {
                timerManager.startRestTimer()
            } label: {
                Image(systemName: "checkmark")
                    .font(.title2)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        } else if timerManager.isRunning {
            HStack(spacing: 12) {
                // Stop
                Button {
                    timerManager.stop()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                
                // Pause/Resume
                Button {
                    timerManager.togglePause()
                } label: {
                    Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(timerManager.isPaused ? .orange : .blue)
            }
        } else {
            // Start
            Button {
                timerManager.start()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }
}

// MARK: - Watch Settings View
struct WatchSettingsView: View {
    @EnvironmentObject var timerManager: WatchTimerManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Settings")
                    .font(.headline)
                
                // Sets
                settingRow(title: "Sets", value: timerManager.settings.sets, range: 1...20) { newValue in
                    timerManager.settings.sets = newValue
                }
                
                // Prepare Time
                settingRow(title: "Prepare", value: timerManager.settings.prepareSeconds, range: 0...60, step: 5) { newValue in
                    timerManager.settings.prepareSeconds = newValue
                }
                
                // Rest Time
                settingRow(title: "Rest", value: timerManager.settings.restSeconds, range: 5...300, step: 5) { newValue in
                    timerManager.settings.restSeconds = newValue
                }
                
                // Train Time (only if not rest-only mode)
                if !timerManager.settings.restOnlyMode {
                    settingRow(title: "Train", value: timerManager.settings.trainSeconds, range: 5...300, step: 5) { newValue in
                        timerManager.settings.trainSeconds = newValue
                    }
                }
                
                // Rest Only Mode Toggle
                Toggle("Rest Only", isOn: $timerManager.settings.restOnlyMode)
                    .padding(.horizontal)
                    .tint(.green)
            }
            .padding(.vertical)
        }
    }
    
    private func settingRow(title: String, value: Int, range: ClosedRange<Int>, step: Int = 1, onChange: @escaping (Int) -> Void) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack {
                Button {
                    let newValue = max(range.lowerBound, value - step)
                    onChange(newValue)
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.bordered)
                
                Text(formatValue(value, forTitle: title))
                    .font(.system(.body, design: .monospaced))
                    .frame(minWidth: 50)
                
                Button {
                    let newValue = min(range.upperBound, value + step)
                    onChange(newValue)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private func formatValue(_ value: Int, forTitle title: String) -> String {
        if title == "Sets" {
            return "\(value)"
        } else {
            let minutes = value / 60
            let seconds = value % 60
            if minutes > 0 {
                return "\(minutes):\(String(format: "%02d", seconds))"
            } else {
                return "\(seconds)s"
            }
        }
    }
}

#Preview {
    WatchContentView()
}
