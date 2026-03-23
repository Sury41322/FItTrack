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

                    // MARK: - Totals Banner
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

                    // MARK: - Meal Sections
                    ForEach(meals, id: \.self) { meal in
                        NutritionMealSection(
                            meal: meal,
                            foods: foodStore.foods(for: meal),
                            meals: meals,
                            onDelete: { food in foodStore.deleteFood(food) },
                            onAdd: {
                                selectedMeal = meal
                                showingAddFood = true
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

// MARK: - NutritionMealSection

struct NutritionMealSection: View {
    let meal: String
    let foods: [FoodEntry]
    let meals: [String]
    let onDelete: (FoodEntry) -> Void
    let onAdd: () -> Void

    @Environment(FoodStore.self) var foodStore
    @State private var foodToEdit: FoodEntry?

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

    var totalCalories: Int {
        foods.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Section header
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
                Button { onAdd() } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.green)
                        .padding(.leading, 8)
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
                // ✅ List for native swipe actions
                List {
                    ForEach(foods) { food in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(food.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
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
                            Text("\(food.calories) kcal")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                        .listRowBackground(Color.gray.opacity(0.07))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                onDelete(food)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                foodToEdit = food
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.green)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .frame(height: CGFloat(foods.count) * 80)
            }
        }
        .background(.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(item: $foodToEdit) { food in
            EditFoodSheet(food: food, meals: meals)
                .environment(foodStore)
        }
    }

    private func formatPortion(_ grams: Double, _ unit: String) -> String {
        if unit == "g" || unit == "ml" { return "\(Int(grams))\(unit)" }
        let unitEnum = PortionUnit(rawValue: unit) ?? .grams
        let amount = grams / unitEnum.gramsEquivalent
        let formatted = amount.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(amount))" : String(format: "%.1f", amount)
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
