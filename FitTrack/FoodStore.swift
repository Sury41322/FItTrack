//
//  FoodStore.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import SwiftData
import Observation

@Observable
class FoodStore {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - All foods (today only)

    var loggedFoods: [FoodEntry] {
        let descriptor = FetchDescriptor<FoodEntry>(
            sortBy: [SortDescriptor(\.date)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return all.filter { Calendar.current.isDateInToday($0.date) }
    }

    // MARK: - Filter by meal

    func foods(for meal: String) -> [FoodEntry] {
        loggedFoods.filter { $0.meal == meal }
    }

    func calories(for meal: String) -> Int {
        foods(for: meal).reduce(0) { $0 + $1.calories }
    }

    // MARK: - Totals

    var totalCalories: Int { loggedFoods.reduce(0) { $0 + $1.calories } }
    var totalProtein: Int  { loggedFoods.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Int    { loggedFoods.reduce(0) { $0 + $1.carbs } }
    var totalFat: Int      { loggedFoods.reduce(0) { $0 + $1.fat } }

    // MARK: - Mutations

    func addFood(_ entry: FoodEntry) {
        modelContext.insert(entry)
        try? modelContext.save()
    }

    func deleteFood(_ entry: FoodEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}
