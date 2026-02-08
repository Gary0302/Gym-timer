//
//  WatchWorkoutManager.swift
//  Gym timer Watch App
//
//  Uses HKWorkoutSession to keep screen on during timer session.
//  Requires: HealthKit capability + workout-processing in Background Modes.
//

import Foundation
import HealthKit

class WatchWorkoutManager: NSObject {
    static let shared = WatchWorkoutManager()
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    
    private override init() {
        super.init()
    }
    
    func startWorkoutSession() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToShare: Set<HKSampleType> = []
        let typesToRead: Set<HKObjectType> = [HKObjectType.workoutType()]
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, _ in
            guard success else { return }
            self?.beginSession()
        }
    }
    
    private func beginSession() {
        guard session == nil else { return }
        
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        
        do {
            let workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutSession.delegate = self
            session = workoutSession
            workoutSession.startActivity(with: Date())
        } catch {
            print("WatchWorkoutManager start error: \(error.localizedDescription)")
        }
    }
    
    func endWorkoutSession() {
        guard let session = session else { return }
        session.end()
        self.session = nil
    }
}

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        if toState == .ended {
            self.session = nil
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        self.session = nil
    }
}
