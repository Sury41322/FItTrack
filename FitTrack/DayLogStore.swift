//
//  DayLogStore.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import Foundation
import SwiftData
import Observation

@Observable
class DayLogStore {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch

    var allLogs: [DayLog] {
        let descriptor = FetchDescriptor<DayLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func log(for date: Date) -> DayLog? {
        let start = Calendar.current.startOfDay(for: date)
        return allLogs.first { Calendar.current.isDate($0.date, inSameDayAs: start) }
    }

    // MARK: - Snapshot

    /// Upsert a single day's data. Used for both today and retroactive updates.
    func snapshotDay(
        date: Date,
        steps: Int,
        calories: Int,
        protein: Int,
        workoutLogged: Bool,
        isRestDay: Bool
    ) {
        if let existing = log(for: date) {
            existing.steps         = steps
            existing.calories      = calories
            existing.protein       = protein
            existing.workoutLogged = workoutLogged
            existing.isRestDay     = isRestDay
        } else {
            modelContext.insert(DayLog(
                date: date,
                steps: steps,
                calories: calories,
                protein: protein,
                workoutLogged: workoutLogged,
                isRestDay: isRestDay
            ))
        }
        try? modelContext.save()
    }

    /// Convenience wrapper for snapshotting today.
    func snapshotToday(
        steps: Int,
        calories: Int,
        protein: Int,
        workoutLogged: Bool,
        isRestDay: Bool
    ) {
        snapshotDay(
            date: .now,
            steps: steps,
            calories: calories,
            protein: protein,
            workoutLogged: workoutLogged,
            isRestDay: isRestDay
        )
    }

    // MARK: - Backfill

    /// True if we already have at least one historical (non-today) log entry.
    /// Used to avoid re-running the full HealthKit backfill on every launch.
    var hasBackfilledHistory: Bool {
        allLogs.contains { !Calendar.current.isDateInToday($0.date) }
    }

    /// Bulk-insert step counts from HealthKit history.
    /// Only updates steps — preserves any existing workout/nutrition data.
    /// Only writes to days where steps == 0 to avoid overwriting fresh data.
    func backfillSteps(_ stepsByDate: [Date: Int]) {
        for (date, steps) in stepsByDate {
            guard steps > 0 else { continue }
            if let existing = log(for: date) {
                if existing.steps == 0 {
                    existing.steps = steps
                }
            } else {
                modelContext.insert(DayLog(date: date, steps: steps))
            }
        }
        try? modelContext.save()
    }

    // MARK: - Calendar Helpers

    /// Returns all 7 days in a given week (Mon–Sun) with their log if available.
    func days(in weekStart: Date) -> [(date: Date, log: DayLog?)] {
        let cal = Calendar.current
        return (0..<7).map { offset in
            let date = cal.date(byAdding: .day, value: offset, to: weekStart)!
            return (date: date, log: log(for: date))
        }
    }

    /// Monday of the week containing a given date.
    func weekStart(for date: Date) -> Date {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        let daysFromMonday = (weekday + 5) % 7
        return cal.startOfDay(for: cal.date(byAdding: .day, value: -daysFromMonday, to: date)!)
    }

    /// Last N weeks of Monday starts, most recent first.
    func recentWeekStarts(count: Int = 8) -> [Date] {
        let thisWeek = weekStart(for: .now)
        return (0..<count).map { offset in
            Calendar.current.date(byAdding: .weekOfYear, value: -offset, to: thisWeek)!
        }
    }
}
