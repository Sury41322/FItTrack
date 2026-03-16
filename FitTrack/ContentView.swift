//
//  ContentView.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
            NutritionView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
            WorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "dumbbell")
                }
            MealsView()
                .tabItem {
                    Label("Meals", systemImage: "calendar")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(FoodStore())
}
