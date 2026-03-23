//
//  ProfileStore.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import SwiftData
import Observation

@Observable
class ProfileStore {
    private var modelContext: ModelContext
    private(set) var profile: UserProfile = UserProfile()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedProfileIfNeeded()
        loadProfile()
    }

    private func loadProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            profile = existing
        }
    }

    private func seedProfileIfNeeded() {
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        try? modelContext.save()
    }

    func save() {
        try? modelContext.save()
        loadProfile()
    }

    // MARK: - Convenience

    var hasCompletedOnboarding: Bool { profile.hasCompletedOnboarding }
    var calorieGoal: Int  { profile.calorieGoal }
    var proteinGoal: Int  { profile.proteinGoal }
    var carbsGoal: Int    { profile.carbsGoal }
    var fatGoal: Int      { profile.fatGoal }
    var stepGoal: Int     { profile.stepGoal }
    var name: String      { profile.name }
    var heightCm: Double  { profile.heightCm }

    // MARK: - TDEE Calculator (Mifflin-St Jeor)

    func calculateTDEE(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: String,
        activityLevel: String,
        goal: String
    ) -> (calories: Int, protein: Int, carbs: Int, fat: Int) {

        let bmr: Double
        if gender == "Male" {
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
        } else {
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 161
        }

        let multiplier: Double
        switch activityLevel {
        case "Sedentary":   multiplier = 1.2
        case "Light":       multiplier = 1.375
        case "Moderate":    multiplier = 1.55
        case "Active":      multiplier = 1.725
        case "Very Active": multiplier = 1.9
        default:            multiplier = 1.55
        }

        var tdee = bmr * multiplier

        switch goal {
        case "Muscle Gain": tdee += 300
        case "Fat Loss":    tdee -= 500
        default:            break
        }

        let calories = Int(tdee.rounded())
        let protein  = Int((tdee * 0.30 / 4).rounded())
        let carbs    = Int((tdee * 0.45 / 4).rounded())
        let fat      = Int((tdee * 0.25 / 9).rounded())

        return (calories, protein, carbs, fat)
    }
}
