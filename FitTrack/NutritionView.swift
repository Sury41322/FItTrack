//
//  NutritionView.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import SwiftData

struct NutritionView: View {
    @Environment(FoodStore.self) var foodStore
    @State private var showingAddFood = false
    @State private var selectedMeal = "Breakfast"

    let meals = ["Breakfast", "Lunch", "Dinner", "Snack"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Total calories banner
                    VStack(spacing: 4) {
                        Text("Total Calories Today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(foodStore.totalCalories) kcal")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.green)

                        HStack(spacing: 20) {
                            MacroLabel(value: foodStore.totalProtein, label: "Protein", color: .blue)
                            MacroLabel(value: foodStore.totalCarbs,   label: "Carbs",   color: .orange)
                            MacroLabel(value: foodStore.totalFat,     label: "Fat",     color: .red)
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Meal sections
                    ForEach(meals, id: \.self) { meal in
                        MealSectionView(
                            meal: meal,
                            foods: foodStore.foods(for: meal),
                            totalCalories: foodStore.calories(for: meal),
                            onDelete: { food in
                                foodStore.deleteFood(food)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Nutrition")
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
}

// MARK: - MealSectionView

struct MealSectionView: View {
    let meal: String
    let foods: [FoodEntry]
    let totalCalories: Int
    let onDelete: (FoodEntry) -> Void

    var mealIcon: String {
        switch meal {
        case "Breakfast": return "sunrise.fill"
        case "Lunch":     return "sun.max.fill"
        case "Dinner":    return "moon.stars.fill"
        case "Snack":     return "leaf.fill"
        default:          return "fork.knife"
        }
    }

    var mealColor: Color {
        switch meal {
        case "Breakfast": return .orange
        case "Lunch":     return .yellow
        case "Dinner":    return .indigo
        case "Snack":     return .green
        default:          return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: mealIcon)
                    .foregroundStyle(mealColor)
                    .font(.system(size: 16))
                Text(meal)
                    .font(.headline)
                Spacer()
                if totalCalories > 0 {
                    Text("\(totalCalories) kcal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(mealColor)
                } else {
                    Text("No food logged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if !foods.isEmpty {
                Divider().padding(.horizontal, 16)
                ForEach(foods) { food in
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(food.name)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            // Portion display
                            Text(formatPortion(food.portionGrams, food.portionUnit))
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                MiniMacro(value: food.protein, label: "P", color: .blue)
                                MiniMacro(value: food.carbs,   label: "C", color: .orange)
                                MiniMacro(value: food.fat,     label: "F", color: .red)
                            }
                        }
                        Spacer()
                        Text("\(food.calories)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

    private func formatPortion(_ grams: Double, _ unit: String) -> String {
        if unit == "g" || unit == "ml" {
            return "\(Int(grams))\(unit)"
        }
        let unitEnum = PortionUnit(rawValue: unit) ?? .grams
        let amount = grams / unitEnum.gramsEquivalent
        let formatted = amount.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(amount))"
            : String(format: "%.1f", amount)
        return "\(formatted) \(unit)"
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    NutritionView()
        .modelContainer(container)
        .environment(FoodStore(modelContext: container.mainContext))
}
