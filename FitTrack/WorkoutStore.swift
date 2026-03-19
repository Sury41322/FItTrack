//
//  WorkoutStore.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import Foundation
import Observation
import SwiftData

@Observable
class WorkoutStore {
    private var modelContext: ModelContext
    private let dayOrder = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var activeSession: WorkoutSession? = nil

    var completedSessions: [WorkoutSession] = []
    var personalBests: [PersonalBest] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedSplitDaysIfNeeded()
        refresh()
    }

    // MARK: - Refresh

    func refresh() {
        let sessionDesc = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        completedSessions = (try? modelContext.fetch(sessionDesc)) ?? []

        let pbDesc = FetchDescriptor<PersonalBest>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        personalBests = (try? modelContext.fetch(pbDesc)) ?? []
    }

    // MARK: - Split Days

    var splitDays: [SplitDay] {
        let descriptor = FetchDescriptor<SplitDay>()
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        return fetched.sorted {
            (dayOrder.firstIndex(of: $0.day) ?? 0) < (dayOrder.firstIndex(of: $1.day) ?? 0)
        }
    }

    private func seedSplitDaysIfNeeded() {
        guard splitDays.isEmpty else { return }
        for day in dayOrder { modelContext.insert(SplitDay(day: day)) }
        try? modelContext.save()
    }

    func saveSplitDay(_ day: SplitDay) {
        try? modelContext.save()
    }

    // MARK: - Sessions

    var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1,
            to: Calendar.current.startOfDay(for: .now))!
    }

    func hasSession(on date: Date) -> Bool {
        completedSessions.contains {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }

    func startSession(name: String, exercises: [SplitExercise]) {
        let session = WorkoutSession(name: name, date: .now)
        session.exercises = exercises.map {
            // Pass restSeconds from the split plan into the active exercise
            ActiveExercise(
                name: $0.name,
                targetSets: $0.targetSets,
                targetReps: $0.targetReps,
                restSeconds: $0.restSeconds
            )
        }
        activeSession = session
    }

    func startEmptySession(name: String) {
        activeSession = WorkoutSession(name: name, date: .now)
    }

    func finishSession(on date: Date? = nil) {
        guard let session = activeSession else { return }

        if let date { session.date = date }
        session.durationSeconds = Int(Date().timeIntervalSince(session.date))

        for exercise in session.exercises {
            guard let best = exercise.bestSet else { continue }
            let key = exercise.name.lowercased()
            let newVolume = best.weight * Double(best.reps)

            if let existing = personalBests.first(where: { $0.exerciseName.lowercased() == key }) {
                if newVolume > existing.weight * Double(existing.reps) {
                    existing.weight = best.weight
                    existing.reps   = best.reps
                    existing.date   = date ?? .now
                }
            } else {
                modelContext.insert(PersonalBest(
                    exerciseName: exercise.name,
                    weight: best.weight,
                    reps: best.reps,
                    date: date ?? .now
                ))
            }
        }

        modelContext.insert(session)
        activeSession = nil
        try? modelContext.save()
        refresh()
    }

    func cancelSession() {
        activeSession = nil
    }

    func deleteSession(_ session: WorkoutSession) {
        for exercise in session.exercises {
            let key = exercise.name.lowercased()
            guard let pb = personalBests.first(where: { $0.exerciseName.lowercased() == key }) else { continue }

            let otherSessions = completedSessions.filter { $0.id != session.id }
            var bestVolumeElsewhere: Double = 0
            var bestSetElsewhere: (weight: Double, reps: Int, date: Date)?

            for other in otherSessions {
                if let ex = other.exercises.first(where: { $0.name.lowercased() == key }),
                   let best = ex.bestSet {
                    let vol = best.weight * Double(best.reps)
                    if vol > bestVolumeElsewhere {
                        bestVolumeElsewhere = vol
                        bestSetElsewhere = (best.weight, best.reps, other.date)
                    }
                }
            }

            if let newBest = bestSetElsewhere {
                pb.weight = newBest.weight
                pb.reps   = newBest.reps
                pb.date   = newBest.date
            } else {
                modelContext.delete(pb)
            }
        }

        modelContext.delete(session)
        try? modelContext.save()
        refresh()
    }

    // MARK: - Personal Bests

    func pb(for exerciseName: String) -> PersonalBest? {
        personalBests.first { $0.exerciseName.lowercased() == exerciseName.lowercased() }
    }

    // MARK: - Helpers

    func lastSets(for exerciseName: String) -> [LoggedSet] {
        for session in completedSessions {
            if let exercise = session.exercises.first(where: {
                $0.name.lowercased() == exerciseName.lowercased()
            }) {
                return exercise.sets
            }
        }
        return []
    }

    func formatDuration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
