//
//  ActivityCalendarView.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI

// MARK: - Day Achievements

struct DayAchievements {
    let workout: Bool
    let steps: Bool
    let protein: Bool
    let rest: Bool
    let isFuture: Bool
    let hasData: Bool

    var dots: [(color: Color, label: String)] {
        var result: [(Color, String)] = []
        if rest    { result.append((.orange, "Rest")) }
        if workout { result.append((.purple, "Workout")) }
        if steps   { result.append((.green,  "Steps")) }
        if protein { result.append((.blue,   "Protein")) }
        return result
    }
}

// MARK: - Activity Calendar View

struct ActivityCalendarView: View {
    @Environment(DayLogStore.self)  var dayLogStore
    @Environment(WorkoutStore.self) var workoutStore

    let stepGoal: Int
    let proteinGoal: Int

    private let weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let cal = Calendar.current

    private var thisWeekStart: Date { dayLogStore.weekStart(for: .now) }
    private var thisWeekDays: [(date: Date, log: DayLog?)] { dayLogStore.days(in: thisWeekStart) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("This week").font(.headline)
                Spacer()
                legendRow
            }

            HStack(spacing: 6) {
                ForEach(thisWeekDays, id: \.date) { entry in
                    dayCellView(date: entry.date, log: entry.log)
                }
            }
        }
        .padding()
        .background(.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Day Cell

    private func dayCellView(date: Date, log: DayLog?) -> some View {
        let achievements = dayAchievements(date: date, log: log)
        let isToday      = cal.isDateInToday(date)
        let dayNum       = cal.component(.day, from: date)
        let weekdayIdx   = weekdayIndex(for: date)

        return VStack(spacing: 4) {
            // Weekday label
            Text(weekdayLabels[weekdayIdx])
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isToday ? .purple : .secondary)

            // Date number + dots
            VStack(spacing: 5) {
                Text("\(dayNum)")
                    .font(.system(size: 13, weight: isToday ? .bold : .regular))
                    .foregroundStyle(achievements.isFuture ? .tertiary : .primary)

                // Dot row — up to 4 dots
                HStack(spacing: 3) {
                    if achievements.dots.isEmpty {
                        Color.clear.frame(width: 5, height: 5)
                    } else {
                        ForEach(achievements.dots, id: \.label) { dot in
                            Circle()
                                .fill(dot.color)
                                .frame(width: 5, height: 5)
                        }
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                isToday
                    ? Color.purple.opacity(0.12)
                    : Color.gray.opacity(achievements.isFuture ? 0.05 : 0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Achievements Logic

    private func dayAchievements(date: Date, log: DayLog?) -> DayAchievements {
        let isFuture = date > .now && !cal.isDateInToday(date)

        // Always derive rest from the weekly split — it is the single source of truth.
        // This ensures the orange dot shows even when no DayLog exists yet, and
        // stays in sync when the user edits their split after logs were written.
        let isRest = isRestDayInSplit(for: date)

        guard !isFuture, let log else {
            return DayAchievements(
                workout: false, steps: false, protein: false,
                rest: isRest && !isFuture,
                isFuture: isFuture, hasData: false
            )
        }

        return DayAchievements(
            workout: log.workoutLogged,
            steps:   log.steps   >= stepGoal,
            protein: log.protein >= proteinGoal,
            rest:    isRest,
            isFuture: false,
            hasData: true
        )
    }

    // MARK: - Rest Day Split Check

    /// iOS weekday: 1=Sun, 2=Mon … 7=Sat → splitDays index: 0=Mon … 6=Sun
    private func isRestDayInSplit(for date: Date) -> Bool {
        let splitIdx: Int
        switch cal.component(.weekday, from: date) {
        case 1: splitIdx = 6
        case 2: splitIdx = 0
        case 3: splitIdx = 1
        case 4: splitIdx = 2
        case 5: splitIdx = 3
        case 6: splitIdx = 4
        case 7: splitIdx = 5
        default: return false
        }
        guard splitIdx < workoutStore.splitDays.count else { return false }
        return workoutStore.splitDays[splitIdx].isRestDay
    }

    /// iOS weekday component → weekdayLabels index (0=Mon … 6=Sun)
    private func weekdayIndex(for date: Date) -> Int {
        switch cal.component(.weekday, from: date) {
        case 1: return 6
        case 2: return 0
        case 3: return 1
        case 4: return 2
        case 5: return 3
        case 6: return 4
        case 7: return 5
        default: return 0
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: 6) {
            legendItem(color: .purple, label: "Workout")
            legendItem(color: .green,  label: "Steps")
            legendItem(color: .blue,   label: "Protein")
            legendItem(color: .orange, label: "Rest")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}
