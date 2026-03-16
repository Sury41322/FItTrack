//
//  FoodEntry.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
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

    init(name: String, calories: Int, protein: Int, carbs: Int, fat: Int, meal: String, date: Date = .now) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.meal = meal
        self.date = date
    }
}
