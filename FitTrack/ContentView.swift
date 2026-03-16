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

    var body: some View {
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
        .environment(FoodStore(modelContext: modelContext))
        .environment(WorkoutStore(modelContext: modelContext))
        .environment(ProfileStore(modelContext: modelContext))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            WorkoutSession.self,
            SplitDay.self,
            PersonalBest.self,
            FoodEntry.self,
            UserProfile.self
        ], inMemory: true)
}
