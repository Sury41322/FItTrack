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

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedSplitDaysIfNeeded()
    }

    // MARK: - Split Days

    var splitDays: [SplitDay] {
        let descriptor = FetchDescriptor<SplitDay>()
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        return fetched.sorted { a, b in
            let ai = dayOrder.firstIndex(of: a.day) ?? 0
            let bi = dayOrder.firstIndex(of: b.day) ?? 0
            return ai < bi
        }
    }

    private func seedSplitDaysIfNeeded() {
        let existing = splitDays
        guard existing.isEmpty else { return }
        for day in dayOrder {
            modelContext.insert(SplitDay(day: day))
        }
        try? modelContext.save()
    }

    func saveSplitDay(_ day: SplitDay) {
        try? modelContext.save()
    }

    // MARK: - Sessions

    var completedSessions: [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func startSession(name: String, exercises: [SplitExercise]) {
        let activeExercises = exercises.map { ex in
            ActiveExercise(name: ex.name, targetSets: ex.targetSets, targetReps: ex.targetReps)
        }
        let session = WorkoutSession(name: name, date: Date())
        session.exercises = activeExercises
        activeSession = session
    }

    func startEmptySession(name: String) {
        activeSession = WorkoutSession(name: name, date: Date())
    }

    func finishSession() {
        guard let session = activeSession else { return }
        session.durationSeconds = Int(Date().timeIntervalSince(session.date))

        for exercise in session.exercises {
            if let best = exercise.bestSet {
                let key = exercise.name.lowercased()
                let existing = personalBests.first { $0.exerciseName.lowercased() == key }
                if let pb = existing {
                    let newVolume = best.weight * Double(best.reps)
                    let existingVolume = pb.weight * Double(pb.reps)
                    if newVolume > existingVolume {
                        pb.weight = best.weight
                        pb.reps = best.reps
                        pb.date = Date()
                    }
                } else {
                    let newPB = PersonalBest(
                        exerciseName: exercise.name,
                        weight: best.weight,
                        reps: best.reps,
                        date: Date()
                    )
                    modelContext.insert(newPB)
                }
            }
        }

        modelContext.insert(session)
        try? modelContext.save()
        activeSession = nil
    }

    func cancelSession() {
        activeSession = nil
    }

    func deleteSession(_ session: WorkoutSession) {
        modelContext.delete(session)
        try? modelContext.save()
    }

    // MARK: - Personal Bests

    var personalBests: [PersonalBest] {
        let descriptor = FetchDescriptor<PersonalBest>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

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
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
