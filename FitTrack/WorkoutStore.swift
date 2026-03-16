//
//  WorkoutStore.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import Foundation
import Observation

@Observable
class WorkoutStore {
    var splitDays: [SplitDay] = [
        SplitDay(day: "Monday"),
        SplitDay(day: "Tuesday"),
        SplitDay(day: "Wednesday"),
        SplitDay(day: "Thursday"),
        SplitDay(day: "Friday"),
        SplitDay(day: "Saturday"),
        SplitDay(day: "Sunday")
    ]

    var completedSessions: [WorkoutSession] = []
    var activeSession: WorkoutSession? = nil
    var personalBests: [String: PersonalBest] = [:]

    func startSession(name: String, exercises: [SplitExercise]) {
        let activeExercises = exercises.map { ex in
            ActiveExercise(
                name: ex.name,
                targetSets: ex.targetSets,
                targetReps: ex.targetReps
            )
        }
        activeSession = WorkoutSession(
            name: name,
            exercises: activeExercises,
            date: Date()
        )
    }

    func startEmptySession(name: String) {
        activeSession = WorkoutSession(
            name: name,
            exercises: [],
            date: Date()
        )
    }

    func finishSession() {
        guard var session = activeSession else { return }
        session.durationSeconds = Int(Date().timeIntervalSince(session.date))

        for exercise in session.exercises {
            if let best = exercise.bestSet {
                let key = exercise.name.lowercased()
                if let existing = personalBests[key] {
                    let newVolume = best.weight * Double(best.reps)
                    let existingVolume = existing.weight * Double(existing.reps)
                    if newVolume > existingVolume {
                        personalBests[key] = PersonalBest(
                            exerciseName: exercise.name,
                            weight: best.weight,
                            reps: best.reps,
                            date: Date()
                        )
                    }
                } else {
                    personalBests[key] = PersonalBest(
                        exerciseName: exercise.name,
                        weight: best.weight,
                        reps: best.reps,
                        date: Date()
                    )
                }
            }
        }

        completedSessions.insert(session, at: 0)
        activeSession = nil
    }

    func cancelSession() {
        activeSession = nil
    }

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

    func pb(for exerciseName: String) -> PersonalBest? {
        personalBests[exerciseName.lowercased()]
    }

    func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
