//
//  DayLog.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import Foundation
import SwiftData

@Model
class DayLog {
    var date: Date          // always stored as start of day
    var steps: Int
    var calories: Int
    var protein: Int
    var workoutLogged: Bool
    var isRestDay: Bool

    init(
        date: Date,
        steps: Int = 0,
        calories: Int = 0,
        protein: Int = 0,
        workoutLogged: Bool = false,
        isRestDay: Bool = false
    ) {
        self.date          = Calendar.current.startOfDay(for: date)
        self.steps         = steps
        self.calories      = calories
        self.protein       = protein
        self.workoutLogged = workoutLogged
        self.isRestDay     = isRestDay
    }
}
