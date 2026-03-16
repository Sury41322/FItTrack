//
//  FoodEntry.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import Foundation

struct FoodEntry: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let meal: String
}
