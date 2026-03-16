//
//  WorkoutModels.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import Foundation

struct LoggedSet: Identifiable {
    let id = UUID()
    var weight: Double
    var reps: Int
    var isWarmup: Bool = false
    var completed: Bool = false
}

struct ActiveExercise: Identifiable {
    let id = UUID()
    var name: String
    var targetSets: Int
    var targetReps: String
    var sets: [LoggedSet] = []

    var bestSet: LoggedSet? {
        sets.filter { !$0.isWarmup && $0.completed }
            .max { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) }
    }

    var totalVolume: Double {
        sets.filter { $0.completed }
            .reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
}

struct WorkoutSession: Identifiable {
    let id = UUID()
    var name: String
    var exercises: [ActiveExercise]
    var date: Date
    var durationSeconds: Int = 0
    var notes: String = ""
}

struct PersonalBest: Identifiable {
    let id = UUID()
    let exerciseName: String
    let weight: Double
    let reps: Int
    let date: Date

    var display: String {
        "\(String(format: "%g", weight))kg × \(reps)"
    }
}

struct SplitExercise: Identifiable {
    let id = UUID()
    var name: String
    var targetSets: Int = 3
    var targetReps: String = "8-12"
}

struct SplitDay: Identifiable {
    let id = UUID()
    var day: String
    var workoutName: String = ""
    var exercises: [SplitExercise] = []
    var isRestDay: Bool = false
}
