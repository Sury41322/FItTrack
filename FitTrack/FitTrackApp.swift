//
//  FitTrackApp.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import SwiftData
import HealthKit

@main
struct FitTrackApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for:
                WorkoutSession.self,
                SplitDay.self,
                PersonalBest.self,
                FoodEntry.self,
                UserProfile.self,
                WeightEntry.self,
                DayLog.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        requestHealthPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }

    private func requestHealthPermission() {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType      = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let distanceType  = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
              let caloriesType  = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let typesToRead: Set<HKQuantityType> = [stepType, distanceType, caloriesType]
        HKHealthStore().requestAuthorization(toShare: nil, read: typesToRead) { _, _ in }
    }
}
