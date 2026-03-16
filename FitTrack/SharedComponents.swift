//
//  SharedComponents.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI

struct MiniMacro: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text("\(value)g")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct MacroLabel: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)g")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct AddFoodSheet: View {
    let meals: [String]
    @Binding var selectedMeal: String
    let onAdd: (FoodEntry) -> Void

    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @Environment(\.dismiss) var dismiss

    var isValid: Bool {
        !foodName.isEmpty && !calories.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Food name")
                            .font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. Idli, Chicken Breast...", text: $foodName)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Meal")
                            .font(.caption).foregroundStyle(.secondary)
                        Picker("Meal", selection: $selectedMeal) {
                            ForEach(meals, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Calories (kcal)")
                            .font(.caption).foregroundStyle(.secondary)
                        TextField("0", text: $calories)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .font(.title2)
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Protein (g)").font(.caption).foregroundStyle(.blue)
                            TextField("0", text: $protein)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Carbs (g)").font(.caption).foregroundStyle(.orange)
                            TextField("0", text: $carbs)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Fat (g)").font(.caption).foregroundStyle(.red)
                            TextField("0", text: $fat)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                    }

                    Button {
                        let entry = FoodEntry(
                            name: foodName,
                            calories: Int(calories) ?? 0,
                            protein: Int(protein) ?? 0,
                            carbs: Int(carbs) ?? 0,
                            fat: Int(fat) ?? 0,
                            meal: selectedMeal
                        )
                        onAdd(entry)
                    } label: {
                        Text("Add to \(selectedMeal)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValid ? .green : .gray)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!isValid)
                }
                .padding()
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
