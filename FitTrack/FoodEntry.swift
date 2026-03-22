//
//  FoodEntry.swift
//  FitTrack
//

import Foundation
import SwiftData

@Model
class FoodEntry {
    var name: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var meal: String
    var date: Date
    var portionGrams: Double
    var portionUnit: String

    init(
        name: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        meal: String,
        date: Date = .now,
        portionGrams: Double = 100,
        portionUnit: String = "g"
    ) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.meal = meal
        self.date = date
        self.portionGrams = portionGrams
        self.portionUnit = portionUnit
    }
}
