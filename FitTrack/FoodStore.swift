//
//  FoodStore.swift
//  FitTrack
//

import SwiftUI
import SwiftData
import Observation

@Observable
class FoodStore {
    private var modelContext: ModelContext
    private(set) var loggedFoods: [FoodEntry] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refresh()
    }

    // MARK: - Refresh

    func refresh() {
        let descriptor = FetchDescriptor<FoodEntry>(
            sortBy: [SortDescriptor(\.date)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []
        loggedFoods = all.filter { Calendar.current.isDateInToday($0.date) }
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
        refresh()
    }

    func deleteFood(_ entry: FoodEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
        refresh()
    }

    func updateFood(
        _ entry: FoodEntry,
        name: String,
        meal: String,
        portionGrams: Double,
        portionUnit: String
    ) {
        let oldScale = entry.portionGrams / 100.0
        let newScale = portionGrams / 100.0

        entry.name     = name
        entry.meal     = meal
        entry.calories = Int((Double(entry.calories) / oldScale * newScale).rounded())
        entry.protein  = Int((Double(entry.protein)  / oldScale * newScale).rounded())
        entry.carbs    = Int((Double(entry.carbs)    / oldScale * newScale).rounded())
        entry.fat      = Int((Double(entry.fat)      / oldScale * newScale).rounded())
        entry.portionGrams = portionGrams
        entry.portionUnit  = portionUnit

        try? modelContext.save()
        refresh()
    }
}
