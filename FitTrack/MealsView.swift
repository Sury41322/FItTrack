//
//  MealsView.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import SwiftData

struct MealsView: View {
    @Environment(FoodStore.self) var foodStore
    @State private var showingAddFood = false
    @State private var selectedMeal = "Breakfast"

    let meals = ["Breakfast", "Lunch", "Dinner", "Snack"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Quick summary card
                    VStack(spacing: 12) {
                        Text("Today's Meals")
                            .font(.headline)

                        HStack(spacing: 0) {
                            ForEach(meals, id: \.self) { meal in
                                VStack(spacing: 4) {
                                    Image(systemName: mealIcon(meal))
                                        .font(.title2)
                                        .foregroundStyle(mealIconColor(meal))
                                    Text(meal)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(foodStore.calories(for: meal))")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(mealColor(meal))
                                    Text("kcal")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding()
                    .background(.gray.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Meal sections
                    ForEach(meals, id: \.self) { meal in
                        MealPlanSection(
                            meal: meal,
                            foods: foodStore.foods(for: meal),
                            onDelete: { food in
                                foodStore.deleteFood(food)
                            },
                            onAdd: {
                                selectedMeal = meal
                                showingAddFood = true
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Meals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFood = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddFood) {
                AddFoodSheet(
                    meals: meals,
                    selectedMeal: $selectedMeal,
                    onAdd: { entry in
                        foodStore.addFood(entry)
                        showingAddFood = false
                    }
                )
            }
        }
    }

    func mealIcon(_ meal: String) -> String {
        switch meal {
        case "Breakfast": return "sunrise.fill"
        case "Lunch": return "sun.max.fill"
        case "Dinner": return "moon.stars.fill"
        case "Snack": return "leaf.fill"
        default: return "fork.knife"
        }
    }

    func mealIconColor(_ meal: String) -> Color {
        switch meal {
        case "Breakfast": return .orange
        case "Lunch": return .yellow
        case "Dinner": return .indigo
        case "Snack": return .green
        default: return .gray
        }
    }

    func mealColor(_ meal: String) -> Color {
        switch meal {
        case "Breakfast": return .orange
        case "Lunch": return .yellow
        case "Dinner": return .indigo
        case "Snack": return .green
        default: return .gray
        }
    }
}

struct MealPlanSection: View {
    let meal: String
    let foods: [FoodEntry]
    let onDelete: (FoodEntry) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack {
                Text(meal)
                    .font(.headline)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if foods.isEmpty {
                Text("Nothing added yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            } else {
                Divider().padding(.horizontal, 16)

                ForEach(foods) { food in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(food.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            HStack(spacing: 10) {
                                MiniMacro(value: food.protein, label: "P", color: .blue)
                                MiniMacro(value: food.carbs, label: "C", color: .orange)
                                MiniMacro(value: food.fat, label: "F", color: .red)
                            }
                        }
                        Spacer()
                        Text("\(food.calories) kcal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                        Button {
                            onDelete(food)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.7))
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .background(.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    MealsView()
        .modelContainer(container)
        .environment(FoodStore(modelContext: container.mainContext))
}
