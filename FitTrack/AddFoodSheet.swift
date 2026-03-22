//
//  AddFoodSheet.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI

// MARK: - Portion unit

enum PortionUnit: String, CaseIterable, Identifiable {
    case grams   = "g"
    case ml      = "ml"
    case cup     = "cup"
    case tbsp    = "tbsp"
    case tsp     = "tsp"
    case piece   = "piece"
    case serving = "serving"

    var id: String { rawValue }

    /// Base grams equivalent — piece and serving are user-defined
    var gramsEquivalent: Double {
        switch self {
        case .grams:   return 1
        case .ml:      return 1
        case .cup:     return 240
        case .tbsp:    return 15
        case .tsp:     return 5
        case .piece:   return 1   // overridden by pieceWeightGrams
        case .serving: return 1   // overridden by pieceWeightGrams
        }
    }

    var needsWeightInput: Bool {
        self == .piece || self == .serving
    }
}

// MARK: - AddFoodSheet

struct AddFoodSheet: View {
    let meals: [String]
    @Binding var selectedMeal: String
    let onAdd: (FoodEntry) -> Void

    @State private var mode: Mode = .search
    @State private var searchText = ""
    @State private var searchService = FoodSearchService()
    @State private var selectedResult: FoodSearchResult?

    @State private var portionAmount: String = "1"
    @State private var portionUnit: PortionUnit = .grams
    @State private var pieceWeightGrams: String = ""   // user fills when unit = piece/serving

    @State private var manualName = ""
    @State private var manualCalories = ""
    @State private var manualProtein = ""
    @State private var manualCarbs = ""
    @State private var manualFat = ""

    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?

    enum Mode { case search, manual }
    enum Field: Hashable {
        case search, portionAmount, pieceWeight
        case manualName, manualCalories, manualProtein, manualCarbs, manualFat
    }

    // MARK: - Computed macros

    private var portionInGrams: Double {
        let amount = Double(portionAmount) ?? 1
        if portionUnit.needsWeightInput {
            let pieceGrams = Double(pieceWeightGrams) ?? 0
            return amount * pieceGrams
        }
        return amount * portionUnit.gramsEquivalent
    }

    private var scaledCalories: Int {
        guard let food = selectedResult, portionInGrams > 0 else { return 0 }
        return Int((food.caloriesPer100g * portionInGrams) / 100)
    }

    private var scaledProtein: Int {
        guard let food = selectedResult, portionInGrams > 0 else { return 0 }
        return Int((food.proteinPer100g * portionInGrams) / 100)
    }

    private var scaledCarbs: Int {
        guard let food = selectedResult, portionInGrams > 0 else { return 0 }
        return Int((food.carbsPer100g * portionInGrams) / 100)
    }

    private var scaledFat: Int {
        guard let food = selectedResult, portionInGrams > 0 else { return 0 }
        return Int((food.fatPer100g * portionInGrams) / 100)
    }

    private var canAdd: Bool {
        if mode == .manual {
            return !manualName.trimmingCharacters(in: .whitespaces).isEmpty
                && Int(manualCalories) != nil
        }
        guard selectedResult != nil, (Double(portionAmount) ?? 0) > 0 else { return false }
        if portionUnit.needsWeightInput {
            return (Double(pieceWeightGrams) ?? 0) > 0
        }
        return true
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    Picker("Mode", selection: $mode) {
                        Text("Search Food").tag(Mode.search)
                        Text("Add Manually").tag(Mode.manual)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: mode) { _, _ in focusedField = nil }

                    mealPicker

                    if mode == .search {
                        searchSection
                    } else {
                        manualSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { commitEntry() }
                        .fontWeight(.semibold)
                        .disabled(!canAdd)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
    }

    // MARK: - Meal Picker

    private var mealPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(meals, id: \.self) { meal in
                    Button {
                        selectedMeal = meal
                    } label: {
                        Text(meal)
                            .font(.subheadline)
                            .fontWeight(selectedMeal == meal ? .semibold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedMeal == meal ? mealColor(meal) : Color.gray.opacity(0.12))
                            .foregroundStyle(selectedMeal == meal ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Search Section

    @ViewBuilder
    private var searchSection: some View {
        VStack(spacing: 16) {

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search food (e.g. banana, chicken…)", text: $searchText)
                    .focused($focusedField, equals: .search)
                    .autocorrectionDisabled()
                    .onChange(of: searchText) { _, newValue in
                        if selectedResult != nil { selectedResult = nil }
                        searchService.search(newValue)
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        selectedResult = nil
                        searchService.clearResults()
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            if searchService.isLoading {
                ProgressView().padding(.top, 24)

            } else if let food = selectedResult {
                selectedFoodCard(food)

            } else if !searchService.results.isEmpty {
                searchResultsList

            } else if let err = searchService.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle).foregroundStyle(.secondary)
                    Text(err)
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Switch to manual entry") { mode = .manual }
                        .font(.subheadline).foregroundStyle(.green)
                }
                .padding(.horizontal, 32).padding(.top, 20)

            } else if !searchText.isEmpty {
                VStack(spacing: 8) {
                    Text("No results found")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button("Add manually instead") { mode = .manual }
                        .font(.subheadline).foregroundStyle(.green)
                }
                .padding(.top, 20)
            }
        }
    }

    private var searchResultsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(searchService.results) { result in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedResult = result
                        searchText = result.name
                        portionAmount = "100"
                        portionUnit = .grams
                        pieceWeightGrams = ""
                    }
                    focusedField = .portionAmount
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.name)
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.primary).lineLimit(1)
                            Text(result.brand)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(result.caloriesPer100g)) kcal")
                                .font(.caption).fontWeight(.semibold).foregroundStyle(.green)
                            Text("per 100g")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }
                Divider().padding(.horizontal, 16)
            }
        }
        .background(Color.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    @ViewBuilder
    private func selectedFoodCard(_ food: FoodSearchResult) -> some View {
        VStack(spacing: 16) {

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name).font(.headline).lineLimit(2)
                    Text(food.brand).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    withAnimation {
                        selectedResult = nil
                        searchText = ""
                        searchService.clearResults()
                    }
                } label: {
                    Text("Change").font(.caption).foregroundStyle(.green)
                }
            }

            Divider()

            // Portion picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Portion")
                    .font(.subheadline).fontWeight(.semibold)

                HStack(spacing: 12) {
                    TextField("Amount", text: $portionAmount)
                        .focused($focusedField, equals: .portionAmount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .frame(width: 80)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PortionUnit.allCases) { unit in
                                Button {
                                    portionUnit = unit
                                    // Reset piece weight when switching units
                                    if !unit.needsWeightInput { pieceWeightGrams = "" }
                                } label: {
                                    Text(unit.rawValue)
                                        .font(.subheadline)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(portionUnit == unit ? Color.green : Color.gray.opacity(0.12))
                                        .foregroundStyle(portionUnit == unit ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                // Show piece weight input only when piece/serving is selected
                if portionUnit.needsWeightInput {
                    HStack(spacing: 10) {
                        Image(systemName: "scalemass")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)

                        Text("1 \(portionUnit.rawValue) =")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("e.g. 50", text: $pieceWeightGrams)
                            .focused($focusedField, equals: .pieceWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .padding(8)
                            .frame(width: 70)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green.opacity(0.4), lineWidth: 1)
                            )

                        Text("g")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(.top, 4)

                    // Helper hint
                    Text("Enter the weight of 1 \(portionUnit.rawValue) in grams")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Live macro preview
            HStack(spacing: 0) {
                MacroPreviewCell(value: scaledCalories, label: "Calories", unit: "kcal", color: .green)
                MacroPreviewCell(value: scaledProtein,  label: "Protein",  unit: "g",    color: .blue)
                MacroPreviewCell(value: scaledCarbs,    label: "Carbs",    unit: "g",    color: .orange)
                MacroPreviewCell(value: scaledFat,      label: "Fat",      unit: "g",    color: .red)
            }

        }
        .padding()
        .background(Color.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: - Manual Section

    private var manualSection: some View {
        VStack(spacing: 14) {
            floatingField("Food name", text: $manualName, focus: .manualName)
            floatingField("Calories (kcal)", text: $manualCalories, focus: .manualCalories, keyboard: .numberPad)

            HStack(spacing: 12) {
                floatingField("Protein (g)", text: $manualProtein, focus: .manualProtein, keyboard: .numberPad)
                floatingField("Carbs (g)",   text: $manualCarbs,   focus: .manualCarbs,   keyboard: .numberPad)
                floatingField("Fat (g)",     text: $manualFat,     focus: .manualFat,     keyboard: .numberPad)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Portion size")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 4)

                HStack(spacing: 12) {
                    TextField("Amount", text: $portionAmount)
                        .focused($focusedField, equals: .portionAmount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .padding(12).frame(width: 80)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PortionUnit.allCases) { unit in
                                Button {
                                    portionUnit = unit
                                    if !unit.needsWeightInput { pieceWeightGrams = "" }
                                } label: {
                                    Text(unit.rawValue)
                                        .font(.subheadline)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(portionUnit == unit ? Color.green : Color.gray.opacity(0.12))
                                        .foregroundStyle(portionUnit == unit ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                if portionUnit.needsWeightInput {
                    HStack(spacing: 10) {
                        Image(systemName: "scalemass")
                            .foregroundStyle(.secondary).font(.subheadline)
                        Text("1 \(portionUnit.rawValue) =")
                            .font(.subheadline).foregroundStyle(.secondary)
                        TextField("e.g. 50", text: $pieceWeightGrams)
                            .focused($focusedField, equals: .pieceWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .padding(8).frame(width: 70)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.4), lineWidth: 1))
                        Text("g").font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.top, 4)

                    Text("Enter the weight of 1 \(portionUnit.rawValue) in grams")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func floatingField(
        _ placeholder: String,
        text: Binding<String>,
        focus: Field,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(placeholder)
                .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 4)
            TextField(placeholder, text: text)
                .focused($focusedField, equals: focus)
                .keyboardType(keyboard)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Commit

    private func commitEntry() {
        let grams = portionInGrams
        let unitString: String
        if portionUnit.needsWeightInput {
            unitString = "\(portionUnit.rawValue) (\(pieceWeightGrams)g each)"
        } else {
            unitString = portionUnit.rawValue
        }

        if mode == .search, let food = selectedResult {
            let entry = FoodEntry(
                name: "\(food.name) – \(food.brand)",
                calories: scaledCalories,
                protein: scaledProtein,
                carbs: scaledCarbs,
                fat: scaledFat,
                meal: selectedMeal,
                portionGrams: grams,
                portionUnit: unitString
            )
            onAdd(entry)

        } else if mode == .manual {
            let entry = FoodEntry(
                name: manualName.trimmingCharacters(in: .whitespaces),
                calories: Int(manualCalories) ?? 0,
                protein: Int(manualProtein) ?? 0,
                carbs: Int(manualCarbs) ?? 0,
                fat: Int(manualFat) ?? 0,
                meal: selectedMeal,
                portionGrams: grams,
                portionUnit: unitString
            )
            onAdd(entry)
        }
    }

    // MARK: - Helpers

    private func mealColor(_ meal: String) -> Color {
        switch meal {
        case "Breakfast": return .orange
        case "Lunch":     return .yellow
        case "Dinner":    return .indigo
        case "Snack":     return .green
        default:          return .gray
        }
    }
}

// MARK: - MacroPreviewCell

struct MacroPreviewCell: View {
    let value: Int
    let label: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3).fontWeight(.bold).foregroundStyle(color)
            Text(unit)
                .font(.caption2).foregroundStyle(.secondary)
            Text(label)
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
