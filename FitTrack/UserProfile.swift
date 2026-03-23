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
    var gender: String          // "Male" / "Female"
    var goal: String            // "Muscle Gain" / "Fat Loss" / "Maintain"
    var activityLevel: String   // "Sedentary" / "Light" / "Moderate" / "Active" / "Very Active"
    var restDays: [String]      // e.g. ["Saturday", "Sunday"]
    var calorieGoal: Int
    var proteinGoal: Int
    var carbsGoal: Int
    var fatGoal: Int
    var stepGoal: Int
    var hasCompletedOnboarding: Bool

    init(
        name: String = "",
        age: Int = 25,
        heightCm: Double = 170,
        weightKg: Double = 70,
        gender: String = "Male",
        goal: String = "Muscle Gain",
        activityLevel: String = "Moderate",
        restDays: [String] = [],
        calorieGoal: Int = 2000,
        proteinGoal: Int = 150,
        carbsGoal: Int = 200,
        fatGoal: Int = 65,
        stepGoal: Int = 10000,
        hasCompletedOnboarding: Bool = false
    ) {
        self.name = name
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.gender = gender
        self.goal = goal
        self.activityLevel = activityLevel
        self.restDays = restDays
        self.calorieGoal = calorieGoal
        self.proteinGoal = proteinGoal
        self.carbsGoal = carbsGoal
        self.fatGoal = fatGoal
        self.stepGoal = stepGoal
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
