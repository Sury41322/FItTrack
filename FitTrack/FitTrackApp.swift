//
//  FitTrackApp.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

//import SwiftUI
//import SwiftData
//
//@main
//struct FitTrackApp: App {
//    var sharedModelContainer: ModelContainer = {
//        let schema = Schema([
//            Item.self,
//        ])
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//
//        do {
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//        .modelContainer(sharedModelContainer)
//    }
//}

//
//  FitTrackApp.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

//import SwiftUI
//
//@main
//struct FitTrackApp: App {
//    @State private var foodStore = FoodStore()
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .environment(foodStore)
//        }
//    }
//}
//
//  FitTrackApp.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import HealthKit

@main
struct FitTrackApp: App {
    @State private var foodStore = FoodStore()

    init() {
        // Request Health permission immediately on app launch
        requestHealthPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(foodStore)
        }
    }

    private func requestHealthPermission() {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
              let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let typesToRead: Set<HKQuantityType> = [stepType, distanceType, caloriesType]
        let store = HKHealthStore()
        store.requestAuthorization(toShare: nil, read: typesToRead) { _, _ in }
    }
}
