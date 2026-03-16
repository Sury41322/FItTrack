//
//  FoodStore.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import Observation

// Single source of truth for all food data
@Observable
class FoodStore {
    var loggedFoods: [FoodEntry] = []

    // Filter by meal
    func foods(for meal: String) -> [FoodEntry] {
        loggedFoods.filter { $0.meal == meal }
    }

    // Calories for a meal
    func calories(for meal: String) -> Int {
        foods(for: meal).reduce(0) { $0 + $1.calories }
    }

    // Total calories
    var totalCalories: Int {
        loggedFoods.reduce(0) { $0 + $1.calories }
    }

    // Total protein
    var totalProtein: Int {
        loggedFoods.reduce(0) { $0 + $1.protein }
    }

    // Total carbs
    var totalCarbs: Int {
        loggedFoods.reduce(0) { $0 + $1.carbs }
    }

    // Total fat
    var totalFat: Int {
        loggedFoods.reduce(0) { $0 + $1.fat }
    }

    // Add food
    func addFood(_ entry: FoodEntry) {
        loggedFoods.append(entry)
    }

    // Delete food
    func deleteFood(_ entry: FoodEntry) {
        loggedFoods.removeAll { $0.id == entry.id }
    }
}
