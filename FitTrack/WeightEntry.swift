//
//  WeightEntry.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import Foundation
import SwiftData

enum Mood: String, Codable, CaseIterable {
    case tired   = "tired"
    case neutral = "neutral"
    case good    = "good"
    case great   = "great"

    var emoji: String {
        switch self {
        case .tired:   return "😴"
        case .neutral: return "😐"
        case .good:    return "🙂"
        case .great:   return "😄"
        }
    }

    var label: String {
        switch self {
        case .tired:   return "Tired"
        case .neutral: return "Okay"
        case .good:    return "Good"
        case .great:   return "Great"
        }
    }
}

@Model
class WeightEntry {
    var weightKg: Double
    var mood: Mood
    var date: Date

    init(weightKg: Double, mood: Mood, date: Date = .now) {
        self.weightKg = weightKg
        self.mood = mood
        self.date = date
    }
}
