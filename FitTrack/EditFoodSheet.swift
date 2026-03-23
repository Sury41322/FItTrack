//
//  EditFoodSheet.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI

struct EditFoodSheet: View {
    @Environment(FoodStore.self) var foodStore
    @Environment(\.dismiss) var dismiss

    let food: FoodEntry
    let meals: [String]

    @State private var name: String
    @State private var selectedMeal: String
    @State private var portionAmount: Double
    @State private var selectedUnit: PortionUnit
    @State private var pieceWeight: Double

    init(food: FoodEntry, meals: [String]) {
        self.food  = food
        self.meals = meals

        _name         = State(initialValue: food.name)
        _selectedMeal = State(initialValue: food.meal)

        let unit   = PortionUnit(rawValue: food.portionUnit) ?? .grams
        let amount = food.portionGrams / unit.gramsEquivalent
        _selectedUnit  = State(initialValue: unit)
        _portionAmount = State(initialValue: amount)
        _pieceWeight   = State(initialValue: unit == .piece ? food.portionGrams / max(1, amount) : 10)
    }

    // MARK: - Computed

    private var computedPortionGrams: Double {
        selectedUnit == .piece
            ? portionAmount * pieceWeight
            : portionAmount * selectedUnit.gramsEquivalent
    }

    private var oldScale: Double { max(food.portionGrams, 1) / 100.0 }
    private var newScale: Double { computedPortionGrams / 100.0 }

    private var previewCalories: Int { Int((Double(food.calories) / oldScale * newScale).rounded()) }
    private var previewProtein:  Int { Int((Double(food.protein)  / oldScale * newScale).rounded()) }
    private var previewCarbs:    Int { Int((Double(food.carbs)    / oldScale * newScale).rounded()) }
    private var previewFat:      Int { Int((Double(food.fat)      / oldScale * newScale).rounded()) }

    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty || portionAmount <= 0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {

                Section("Food Name") {
                    TextField("Name", text: $name)
                }

                Section("Meal") {
                    Picker("Meal", selection: $selectedMeal) {
                        ForEach(meals, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Portion") {
                    Picker("Unit", selection: $selectedUnit) {
                        ForEach(PortionUnit.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("Amount", value: $portionAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(selectedUnit.rawValue)
                            .foregroundStyle(.secondary)
                    }

                    if selectedUnit == .piece {
                        HStack {
                            Text("1 piece =")
                            Spacer()
                            TextField("g", value: $pieceWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("g")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Updated Nutrition") {
                    HStack {
                        Text("Calories")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(previewCalories) kcal")
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    HStack(spacing: 20) {
                        MiniMacro(value: previewProtein, label: "P", color: .blue)
                        MiniMacro(value: previewCarbs,   label: "C", color: .orange)
                        MiniMacro(value: previewFat,     label: "F", color: .red)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        foodStore.updateFood(
                            food,
                            name: name,
                            meal: selectedMeal,
                            portionGrams: computedPortionGrams,
                            portionUnit: selectedUnit.rawValue
                        )
                        dismiss()
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }
}
