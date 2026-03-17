//
//  ContentView.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showWeighIn = false

    // Hold stores as @State so they are created once and reused —
    // not re-created on every render which caused splitDays to be empty
    @State private var foodStore: FoodStore?
    @State private var workoutStore: WorkoutStore?
    @State private var profileStore: ProfileStore?
    @State private var weightStore: WeightStore?
    @State private var dayLogStore: DayLogStore?

    var body: some View {
        Group {
            if let food = foodStore,
               let workout = workoutStore,
               let profile = profileStore,
               let weight = weightStore,
               let dayLog = dayLogStore {
                TabView {
                    DashboardView()
                        .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }
                    NutritionView()
                        .tabItem { Label("Nutrition", systemImage: "fork.knife") }
                    WorkoutView()
                        .tabItem { Label("Workout", systemImage: "dumbbell") }
                    MealsView()
                        .tabItem { Label("Meals", systemImage: "calendar") }
                }
                .environment(food)
                .environment(workout)
                .environment(profile)
                .environment(weight)
                .environment(dayLog)
                .onAppear {
                    if !weight.hasLoggedToday { showWeighIn = true }
                }
                .fullScreenCover(isPresented: $showWeighIn) {
                    MorningWeighInView()
                        .environment(weight)
                        .environment(profile)
                }
            }
        }
        .onAppear {
            if foodStore == nil    { foodStore    = FoodStore(modelContext: modelContext) }
            if workoutStore == nil { workoutStore = WorkoutStore(modelContext: modelContext) }
            if profileStore == nil { profileStore = ProfileStore(modelContext: modelContext) }
            if weightStore == nil  { weightStore  = WeightStore(modelContext: modelContext) }
            if dayLogStore == nil  { dayLogStore  = DayLogStore(modelContext: modelContext) }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            WorkoutSession.self,
            SplitDay.self,
            PersonalBest.self,
            FoodEntry.self,
            UserProfile.self,
            WeightEntry.self,
            DayLog.self
        ], inMemory: true)
}
