//
//  OnboardingView.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(ProfileStore.self) var profileStore
    @State private var currentPage = 0

    @State private var name = ""
    @State private var age = ""
    @State private var gender = "Male"
    @State private var heightCm = ""
    @State private var weightKg = ""
    @State private var goal = "Muscle Gain"
    @State private var activityLevel = "Moderate"
    @State private var restDays: Set<String> = []

    @State private var calories: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var steps: Double = 10000

    @State private var editingField: ActiveField? = nil

    enum ActiveField { case calories, protein, carbs, fat, steps }

    let allDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    let goals = ["Muscle Gain", "Fat Loss", "Maintain"]
    let activityLevels = ["Sedentary", "Light", "Moderate", "Active", "Very Active"]
    let totalPages = 6

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                switch currentPage {
                case 0: pageWelcome
                case 1: pageBodyStats
                case 2: pageGoal
                case 3: pageActivity
                case 4: pageTargets.onAppear { recalculate() }
                case 5: pageSummary
                default: pageWelcome
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        ForEach(0..<totalPages, id: \.self) { i in
                            Circle()
                                .fill(i <= currentPage ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentPage > 0 {
                        Button {
                            withAnimation(.easeInOut) { currentPage -= 1 }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left").fontWeight(.semibold)
                                Text("Back")
                            }
                            .foregroundStyle(.green)
                        }
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    // MARK: - Pages

    var pageWelcome: some View {
        OnboardingPageShell(
            icon: "figure.run", color: .green,
            title: "Welcome to FitTrack",
            subtitle: "Let's set up your profile to personalise your experience.",
            isValid: !name.trimmingCharacters(in: .whitespaces).isEmpty && Int(age) != nil,
            onNext: advance
        ) {
            VStack(spacing: 14) {
                AppleField(placeholder: "Your Name", text: $name, icon: "person.fill", color: .green)
                AppleField(placeholder: "Age", text: $age, icon: "calendar", color: .green, keyboard: .numberPad)
                HStack(spacing: 12) {
                    ForEach(["Male", "Female"], id: \.self) { g in
                        GenderCard(label: g, isSelected: gender == g) { gender = g }
                    }
                }
            }
        }
    }

    var pageBodyStats: some View {
        OnboardingPageShell(
            icon: "scalemass.fill", color: .blue,
            title: "Your Body Stats",
            subtitle: "Used to calculate your daily calorie needs accurately.",
            isValid: Double(heightCm) != nil && Double(weightKg) != nil,
            onNext: advance
        ) {
            VStack(spacing: 14) {
                AppleField(placeholder: "Height (cm)", text: $heightCm, icon: "ruler.fill", color: .blue, keyboard: .decimalPad)
                AppleField(placeholder: "Weight (kg)", text: $weightKg, icon: "scalemass.fill", color: .blue, keyboard: .decimalPad)
            }
        }
    }

    var pageGoal: some View {
        OnboardingPageShell(
            icon: "target", color: .orange,
            title: "What's Your Goal?",
            subtitle: "We'll adjust your calories based on what you're working towards.",
            isValid: true,
            onNext: advance
        ) {
            VStack(spacing: 10) {
                ForEach(goals, id: \.self) { g in
                    OptionRow(title: g, subtitle: goalSubtitle(g), icon: goalIcon(g),
                              isSelected: goal == g, color: .orange) { goal = g }
                }
            }
        }
    }

    var pageActivity: some View {
        OnboardingPageShell(
            icon: "bolt.fill", color: .yellow,
            title: "Activity Level",
            subtitle: "How active are you on a typical week?",
            isValid: true,
            onNext: advance
        ) {
            VStack(spacing: 10) {
                ForEach(activityLevels, id: \.self) { level in
                    OptionRow(title: level, subtitle: activitySubtitle(level), icon: activityIcon(level),
                              isSelected: activityLevel == level, color: .yellow) { activityLevel = level }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Rest Days").font(.headline)
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 8) {
                        ForEach(allDays, id: \.self) { day in
                            let selected = restDays.contains(day)
                            Button {
                                if selected { restDays.remove(day) } else { restDays.insert(day) }
                            } label: {
                                Text(String(day.prefix(3)))
                                    .font(.caption).fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selected ? Color.yellow.opacity(0.2) : Color(.secondarySystemBackground))
                                    .foregroundStyle(selected ? Color.yellow : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(selected ? Color.yellow : Color.clear, lineWidth: 1.5))
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    var pageTargets: some View {
        OnboardingPageShell(
            icon: "chart.bar.fill", color: .purple,
            title: "Your Daily Targets",
            subtitle: "Auto-calculated from your stats. Adjust any value and others update automatically.",
            isValid: calories > 0 && protein > 0,
            onNext: advance
        ) {
            VStack(spacing: 14) {
                TargetField(label: "Calories", unit: "kcal", icon: "flame.fill", color: .orange, value: $calories) {
                    if editingField == .calories {
                        protein = (calories * 0.30 / 4).rounded()
                        carbs   = (calories * 0.45 / 4).rounded()
                        fat     = (calories * 0.25 / 9).rounded()
                    }
                }
                .simultaneousGesture(TapGesture().onEnded { editingField = .calories })

                TargetField(label: "Protein", unit: "g", icon: "p.circle.fill", color: .blue, value: $protein) {
                    if editingField == .protein { recalcCaloriesFromMacros() }
                }
                .simultaneousGesture(TapGesture().onEnded { editingField = .protein })

                TargetField(label: "Carbs", unit: "g", icon: "c.circle.fill", color: .orange, value: $carbs) {
                    if editingField == .carbs { recalcCaloriesFromMacros() }
                }
                .simultaneousGesture(TapGesture().onEnded { editingField = .carbs })

                TargetField(label: "Fat", unit: "g", icon: "f.circle.fill", color: .red, value: $fat) {
                    if editingField == .fat { recalcCaloriesFromMacros() }
                }
                .simultaneousGesture(TapGesture().onEnded { editingField = .fat })

                TargetField(label: "Daily Steps", unit: "steps", icon: "figure.walk", color: .purple, value: $steps) {}
                    .simultaneousGesture(TapGesture().onEnded { editingField = .steps })

                MacroSplitBar(calories: calories, protein: protein, carbs: carbs, fat: fat)
                    .padding(.top, 4)
            }
        }
    }

    var pageSummary: some View {
        OnboardingPageShell(
            icon: "checkmark.seal.fill", color: .green,
            title: "You're All Set!",
            subtitle: "Your profile is ready. Let's start tracking.",
            isValid: true,
            buttonLabel: "Start Tracking",
            onNext: finishOnboarding
        ) {
            VStack(spacing: 10) {
                SummaryRow(label: "Name",      value: name,                    color: .purple)
                SummaryRow(label: "Goal",      value: goal,                    color: .orange)
                SummaryRow(label: "Calories",  value: "\(Int(calories)) kcal", color: .green)
                SummaryRow(label: "Protein",   value: "\(Int(protein))g",      color: .blue)
                SummaryRow(label: "Activity",  value: activityLevel,           color: .yellow)
                SummaryRow(label: "Rest Days", value: restDays.isEmpty ? "None" : restDays.sorted().map { String($0.prefix(3)) }.joined(separator: ", "), color: .gray)
            }
        }
    }

    // MARK: - Auto-adjust

    func recalcCaloriesFromMacros() {
        calories = (protein * 4 + carbs * 4 + fat * 9).rounded()
    }

    // MARK: - Actions

    func advance() {
        hideKeyboard()
        withAnimation(.easeInOut) { currentPage += 1 }
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    func recalculate() {
        guard let w = Double(weightKg), let h = Double(heightCm), let a = Int(age) else { return }
        let r = profileStore.calculateTDEE(weightKg: w, heightCm: h, age: a,
                                           gender: gender, activityLevel: activityLevel, goal: goal)
        calories = Double(r.calories)
        protein  = Double(r.protein)
        carbs    = Double(r.carbs)
        fat      = Double(r.fat)
    }

    func finishOnboarding() {
        hideKeyboard()
        let p = profileStore.profile
        p.name                   = name
        p.age                    = Int(age)         ?? 25
        p.heightCm               = Double(heightCm) ?? 170
        p.weightKg               = Double(weightKg) ?? 70
        p.gender                 = gender
        p.goal                   = goal
        p.activityLevel          = activityLevel
        p.restDays               = Array(restDays)
        p.calorieGoal            = Int(calories)
        p.proteinGoal            = Int(protein)
        p.carbsGoal              = Int(carbs)
        p.fatGoal                = Int(fat)
        p.stepGoal               = Int(steps)
        p.hasCompletedOnboarding = true
        profileStore.save()
    }

    // MARK: - Helpers

    func goalSubtitle(_ g: String) -> String {
        switch g {
        case "Muscle Gain": return "+300 kcal surplus"
        case "Fat Loss":    return "-500 kcal deficit"
        default:            return "Maintenance calories"
        }
    }
    func goalIcon(_ g: String) -> String {
        switch g {
        case "Muscle Gain": return "dumbbell.fill"
        case "Fat Loss":    return "flame.fill"
        default:            return "equal.circle.fill"
        }
    }
    func activitySubtitle(_ l: String) -> String {
        switch l {
        case "Sedentary":   return "Little or no exercise"
        case "Light":       return "1–3 days/week"
        case "Moderate":    return "3–5 days/week"
        case "Active":      return "6–7 days/week"
        case "Very Active": return "Twice a day or physical job"
        default:            return ""
        }
    }
    func activityIcon(_ l: String) -> String {
        switch l {
        case "Sedentary":   return "sofa.fill"
        case "Light":       return "figure.walk"
        case "Moderate":    return "figure.run"
        case "Active":      return "figure.strengthtraining.traditional"
        case "Very Active": return "bolt.fill"
        default:            return "figure.run"
        }
    }
}

// MARK: - TargetField

struct TargetField: View {
    let label: String
    let unit: String
    let icon: String
    let color: Color
    @Binding var value: Double
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.subheadline).fontWeight(.semibold)
                .frame(width: 70)
                .onChange(of: value) { onChange() }
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - MacroSplitBar

struct MacroSplitBar: View {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    var proteinKcal: Double { protein * 4 }
    var carbsKcal: Double   { carbs * 4 }
    var fatKcal: Double     { fat * 9 }
    var total: Double       { max(proteinKcal + carbsKcal + fatKcal, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Macro Split")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geo.size.width * proteinKcal / total)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: geo.size.width * carbsKcal / total)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red)
                        .frame(width: geo.size.width * fatKcal / total)
                }
                .frame(height: 8)
            }
            .frame(height: 8)

            HStack(spacing: 16) {
                MacroSplitLabel(color: .blue,   label: "Protein", pct: proteinKcal / total)
                MacroSplitLabel(color: .orange, label: "Carbs",   pct: carbsKcal / total)
                MacroSplitLabel(color: .red,    label: "Fat",     pct: fatKcal / total)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MacroSplitLabel: View {
    let color: Color
    let label: String
    let pct: Double

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label) \(Int(pct * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - OnboardingPageShell

struct OnboardingPageShell<Content: View>: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let isValid: Bool
    var buttonLabel: String = "Next"
    let onNext: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.12))
                            .frame(width: 88, height: 88)
                        Image(systemName: icon)
                            .font(.system(size: 36))
                            .foregroundStyle(color)
                    }
                    .padding(.top, 32)

                    VStack(spacing: 8) {
                        Text(title)
                            .font(.title2).fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    content()
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 24)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            VStack {
                Divider()
                Button(action: onNext) {
                    Text(buttonLabel)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid ? color : Color.gray.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!isValid)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(Color(.systemBackground))
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - AppleField

struct AppleField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = ""
    var color: Color = .green
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 22)
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - OptionRow

struct OptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color.opacity(0.15) : Color(.secondarySystemBackground))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundStyle(isSelected ? color : .secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? color : Color.gray.opacity(0.3))
                    .font(.title3)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? color : Color.clear, lineWidth: 1.5))
        }
    }
}

// MARK: - GenderCard

struct GenderCard: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(isSelected ? .blue : .secondary)
                    Text(label)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
                Spacer()
            }
            .padding(.vertical, 18)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5))
        }
    }
}

// MARK: - SummaryRow

struct SummaryRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, configurations: config)
    OnboardingView()
        .modelContainer(container)
        .environment(ProfileStore(modelContext: container.mainContext))
}
