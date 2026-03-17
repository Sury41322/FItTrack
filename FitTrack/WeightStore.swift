//
//  WeightStore.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import SwiftData
import Observation

@Observable
class WeightStore {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // All entries sorted newest first
    var allEntries: [WeightEntry] {
        let descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // True if the user has already logged weight today
    var hasLoggedToday: Bool {
        allEntries.contains { Calendar.current.isDateInToday($0.date) }
    }

    // Last 7 days of entries for the chart (oldest → newest)
    var last7Days: [WeightEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: .now))!
        return allEntries
            .filter { $0.date >= cutoff }
            .reversed()
    }

    // Most recent entry
    var latestEntry: WeightEntry? {
        allEntries.first
    }

    func log(weightKg: Double, mood: Mood) {
        let entry = WeightEntry(weightKg: weightKg, mood: mood)
        modelContext.insert(entry)
        try? modelContext.save()
    }
}
