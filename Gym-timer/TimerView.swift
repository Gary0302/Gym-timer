//
//  TimerView.swift
//  Gym timer
//
//  Created by Gary yang on 2026/1/29.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var showSettings = false
    
    private var l10n: L10n {
        languageManager.l10n
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                Spacer()
                    .frame(maxHeight: 40)
                
                // Main Timer Display - fixed position
                timerDisplayView
                    .frame(height: 300)
                
                Spacer()
                    .frame(height: 24)
                
                // Set Progress
                setProgressView
                
                // Skip & Restart Buttons - fixed height container (hide when waiting for tap)
                skipRestartButtons
                    .frame(height: 70)
                    .opacity(timerManager.isRunning && timerManager.currentPhase != .waitingForTap ? 1 : 0)
                
                Spacer()
                
                // Control Buttons
                controlButtonsView
                    .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(timerManager: timerManager)
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                timerManager.currentPhase.color.opacity(0.3),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .animation(.easeInOut(duration: 0.5), value: timerManager.currentPhase)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.appTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if timerManager.isRunning {
                    Text(l10n.phaseName(for: timerManager.currentPhase))
                        .font(.subheadline)
                        .foregroundColor(timerManager.currentPhase.color)
                        .fontWeight(.semibold)
                } else {
                    // Show current settings summary when idle
                    let total = timerManager.settings.totalDuration
                    let mins = total / 60
                    let secs = total % 60
                    Text("\(timerManager.settings.sets) \(l10n.setsUnit) · \(l10n.totalDuration): \(mins):\(String(format: "%02d", secs))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Settings button - only show when not running
            if !timerManager.isRunning {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .animation(.easeInOut(duration: 0.2), value: timerManager.isRunning)
    }
    
    // MARK: - Timer Display
    private var timerDisplayView: some View {
        ZStack {
            // Progress Ring Background
            Circle()
                .stroke(
                    timerManager.currentPhase.color.opacity(0.2),
                    lineWidth: 20
                )
                .frame(width: 280, height: 280)
            
            // Progress Ring
            Circle()
                .trim(from: 0, to: timerManager.progressPercentage)
                .stroke(
                    timerManager.currentPhase.color,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: timerManager.progressPercentage)
            
            // Center Content
            VStack(spacing: 12) {
                // Phase Icon
                Image(systemName: timerManager.currentPhase.systemImage)
                    .font(.system(size: 40))
                    .foregroundColor(timerManager.currentPhase.color)
                
                // Time Display or Waiting Message
                if timerManager.currentPhase == .waitingForTap {
                    Text(l10n.phaseName(for: timerManager.currentPhase))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(timerManager.currentPhase.color)
                } else {
                    Text(timerManager.formattedTime)
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                
                // Phase Name
                Text(l10n.phaseName(for: timerManager.currentPhase))
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .opacity(timerManager.currentPhase == .waitingForTap ? 0 : 1)
            }
        }
    }
    
    // MARK: - Set Progress
    private var setProgressView: some View {
        VStack(spacing: 12) {
            Text(l10n.progress)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(1...timerManager.settings.sets, id: \.self) { set in
                    Circle()
                        .fill(setColor(for: set))
                        .frame(width: 24, height: 24)
                        .overlay {
                            if set == timerManager.currentSet && timerManager.isRunning {
                                Circle()
                                    .stroke(timerManager.currentPhase.color, lineWidth: 2)
                                    .scaleEffect(1.3)
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: timerManager.currentSet)
                }
            }
            
            Text(l10n.setProgress(current: timerManager.currentSet, total: timerManager.settings.sets))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
    
    private func setColor(for set: Int) -> Color {
        if set < timerManager.currentSet {
            return .green
        } else if set == timerManager.currentSet && timerManager.isRunning {
            return timerManager.currentPhase.color.opacity(0.5)
        } else {
            return Color.secondary.opacity(0.3)
        }
    }
    
    // MARK: - Skip & Restart Buttons
    private var skipRestartButtons: some View {
        HStack(spacing: 40) {
            // Restart Section Button
            Button {
                timerManager.restartCurrentSection()
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                    Text(l10n.restartSection)
                        .font(.caption)
                }
                .foregroundColor(.orange)
                .frame(width: 80)
            }
            .disabled(!timerManager.isRunning)
            
            // Next Section Button
            Button {
                timerManager.skipToNextSection()
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                    Text(l10n.nextSection)
                        .font(.caption)
                }
                .foregroundColor(.blue)
                .frame(width: 80)
            }
            .disabled(!timerManager.isRunning)
        }
        .animation(.easeInOut(duration: 0.3), value: timerManager.isRunning)
    }
    
    // MARK: - Control Buttons
    private var controlButtonsView: some View {
        HStack(spacing: 32) {
            // Stop Button
            if timerManager.isRunning {
                Button {
                    timerManager.stop()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "stop.fill")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Main Button (Start / Pause / Resume / Done)
            if timerManager.currentPhase == .waitingForTap {
                // Checkmark button for "done with set"
                Button {
                    timerManager.startRestTimer()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.green.gradient)
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.green.opacity(0.4), radius: 10, y: 5)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            } else {
                Button {
                    if timerManager.isRunning {
                        timerManager.togglePause()
                    } else {
                        timerManager.start()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(mainButtonColor.gradient)
                            .frame(width: 90, height: 90)
                            .shadow(color: mainButtonColor.opacity(0.4), radius: 10, y: 5)
                        
                        Image(systemName: mainButtonIcon)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Placeholder for symmetry when not running
            if timerManager.isRunning {
                // Empty space for balance
                Circle()
                    .fill(Color.clear)
                    .frame(width: 70, height: 70)
            }
        }
    }
    
    private var mainButtonColor: Color {
        if !timerManager.isRunning {
            return .green
        } else if timerManager.isPaused {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var mainButtonIcon: String {
        if !timerManager.isRunning {
            return "play.fill"
        } else if timerManager.isPaused {
            return "play.fill"
        } else {
            return "pause.fill"
        }
    }
}

// MARK: - Summary Card (for idle state)
struct SummaryCard: View {
    let settings: TimerSettings
    @ObservedObject var languageManager = LanguageManager.shared
    
    private var l10n: L10n {
        languageManager.l10n
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                SummaryItem(value: "\(settings.sets)", label: l10n.sets, color: .purple)
                SummaryItem(value: formatTime(settings.prepareSeconds), label: l10n.phasePrepare, color: .orange)
                SummaryItem(value: formatTime(settings.trainSeconds), label: l10n.phaseTrain, color: .green)
                SummaryItem(value: formatTime(settings.restSeconds), label: l10n.phaseRest, color: .blue)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 24)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let min = seconds / 60
            let sec = seconds % 60
            return sec > 0 ? "\(min):\(String(format: "%02d", sec))" : "\(min)\(l10n.minutes)"
        }
        return "\(seconds)\(l10n.seconds)"
    }
}

struct SummaryItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    TimerView(timerManager: TimerManager.shared)
}
