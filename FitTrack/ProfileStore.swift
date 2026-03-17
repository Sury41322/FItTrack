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

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedProfileIfNeeded()
    }

    var profile: UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        return (try? modelContext.fetch(descriptor))?.first ?? UserProfile()
    }

    private func seedProfileIfNeeded() {
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        modelContext.insert(UserProfile())
        try? modelContext.save()
    }

    func save() {
        try? modelContext.save()
    }

    var calorieGoal: Int { profile.calorieGoal }
    var stepGoal: Int { profile.stepGoal }
    var name: String { profile.name }
    var heightCm: Double { profile.heightCm }
}
