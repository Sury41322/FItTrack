//
//  UserProfile.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import Foundation
import SwiftData

@Model
class UserProfile {
    var name: String
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var calorieGoal: Int
    var stepGoal: Int

    init(
        name: String = "",
        age: Int = 25,
        heightCm: Double = 170,
        weightKg: Double = 70,
        calorieGoal: Int = 2000,
        stepGoal: Int = 10000
    ) {
        self.name = name
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.calorieGoal = calorieGoal
        self.stepGoal = stepGoal
    }
}
