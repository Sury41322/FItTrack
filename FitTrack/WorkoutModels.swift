//
//  WorkoutModels.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import Foundation
import SwiftData

@Model
class LoggedSet {
    var weight: Double
    var reps: Int
    var isWarmup: Bool
    var completed: Bool

    init(weight: Double, reps: Int, isWarmup: Bool = false, completed: Bool = false) {
        self.weight = weight
        self.reps = reps
        self.isWarmup = isWarmup
        self.completed = completed
    }

    var display: String {
        "\(String(format: "%g", weight))kg × \(reps)"
    }
}

@Model
class ActiveExercise {
    var name: String
    var targetSets: Int
    var targetReps: String
    @Relationship(deleteRule: .cascade) var sets: [LoggedSet] = []

    var bestSet: LoggedSet? {
        sets.filter { !$0.isWarmup && $0.completed }
            .max { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) }
    }

    var totalVolume: Double {
        sets.filter { $0.completed }
            .reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    init(name: String, targetSets: Int, targetReps: String) {
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
    }
}

@Model
class WorkoutSession {
    var name: String
    var date: Date
    var durationSeconds: Int
    var notes: String
    @Relationship(deleteRule: .cascade) var exercises: [ActiveExercise] = []

    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.totalVolume }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.filter { $0.completed && !$0.isWarmup }.count }
    }

    init(name: String, date: Date = .now, durationSeconds: Int = 0, notes: String = "") {
        self.name = name
        self.date = date
        self.durationSeconds = durationSeconds
        self.notes = notes
    }
}

@Model
class PersonalBest {
    var exerciseName: String
    var weight: Double
    var reps: Int
    var date: Date

    var display: String {
        "\(String(format: "%g", weight))kg × \(reps)"
    }

    init(exerciseName: String, weight: Double, reps: Int, date: Date = .now) {
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.date = date
    }
}

@Model
class SplitExercise {
    var name: String
    var targetSets: Int
    var targetReps: String

    init(name: String, targetSets: Int = 3, targetReps: String = "8-12") {
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
    }
}

@Model
class SplitDay {
    var day: String
    var workoutName: String
    var isRestDay: Bool
    @Relationship(deleteRule: .cascade) var exercises: [SplitExercise] = []

    init(day: String, workoutName: String = "", isRestDay: Bool = false) {
        self.day = day
        self.workoutName = workoutName
        self.isRestDay = isRestDay
    }
}
