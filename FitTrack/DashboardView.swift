//
//  DashboardView.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import SwiftData
import HealthKit
import Combine
import CoreMotion

// MARK: - Step Counter Service

class StepCounterService: ObservableObject {
    private let healthStore = HKHealthStore()
    private let pedometer = CMPedometer()

    @Published var steps: Int = 0
    @Published var distance: Double = 0
    @Published var activeCalories: Double = 0
    @Published var isAvailable: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var isMotionAuthorized: Bool = false

    private var observerQueries: [HKObserverQuery] = []

    init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
        if isAvailable {
            requestAndStart()
        }
    }

    func requestAndStart() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
              let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let typesToRead: Set<HKQuantityType> = [stepType, distanceType, caloriesType]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchTodayData()
                    self.startHealthKitObservers()
                }
            }
        }

        if CMMotionActivityManager.isActivityAvailable() {
            let activityManager = CMMotionActivityManager()
            activityManager.startActivityUpdates(to: .main) { _ in }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                activityManager.stopActivityUpdates()
                self.isMotionAuthorized = true
                self.startPedometerUpdates()
            }
        }
    }

    private func startPedometerUpdates() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        pedometer.startUpdates(from: startOfDay) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                self?.steps = data.numberOfSteps.intValue
                self?.distance = data.distance?.doubleValue ?? 0
            }
        }
    }

    private func startHealthKitObservers() {
        startObserver(for: .activeEnergyBurned) { self.fetchActiveCalories() }
    }

    private func startObserver(for identifier: HKQuantityTypeIdentifier, onUpdate: @escaping () -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { _, _ in }
        let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completionHandler, error in
            guard error == nil else { completionHandler(); return }
            onUpdate()
            completionHandler()
        }
        healthStore.execute(query)
        observerQueries.append(query)
    }

    func fetchTodayData() {
        fetchActiveCalories()
    }

    private func fetchActiveCalories() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let query = HKStatisticsQuery(
            quantityType: type,
            quantitySamplePredicate: todayPredicate(),
            options: .cumulativeSum
        ) { _, result, _ in
            DispatchQueue.main.async {
                self.activeCalories = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            }
        }
        healthStore.execute(query)
    }

    private func todayPredicate() -> NSPredicate {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )
    }

    var distanceKm: String {
        String(format: "%.2f km", distance / 1000)
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @Environment(FoodStore.self) var foodStore
    @Environment(ProfileStore.self) var profileStore
    @StateObject private var stepService = StepCounterService()
    @State private var showingProfile = false

    let proteinGoal = 150
    let carbsGoal = 200
    let fatGoal = 65

    var calorieGoal: Int { profileStore.calorieGoal }
    var stepGoal: Int { profileStore.stepGoal }

    var calorieProgress: Double {
        min(Double(foodStore.totalCalories) / Double(calorieGoal), 1.0)
    }

    var stepProgress: Double {
        min(Double(stepService.steps) / Double(stepGoal), 1.0)
    }

    var caloriesFromSteps: Int {
        Int(Double(stepService.steps) * 0.04)
    }

    var stepsRemaining: Int {
        max(0, stepGoal - stepService.steps)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Greeting header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(greeting)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(profileStore.name.isEmpty ? "Here's your day" : "Hey, \(profileStore.name.split(separator: " ").first.map(String.init) ?? profileStore.name) 👋")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)

                    // Calories card
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Calories today")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text("\(foodStore.totalCalories)")
                                        .font(.system(size: 42, weight: .bold))
                                        .foregroundStyle(.green)
                                    Text("/ \(calorieGoal) kcal")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            RingView(progress: calorieProgress, color: .green)
                        }
                        ProgressView(value: calorieProgress)
                            .tint(.green)
                    }
                    .padding()
                    .background(.green.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Macros row
                    HStack(spacing: 12) {
                        MacroCard(title: "Protein", current: foodStore.totalProtein, goal: proteinGoal, unit: "g", color: .blue)
                        MacroCard(title: "Carbs", current: foodStore.totalCarbs, goal: carbsGoal, unit: "g", color: .orange)
                        MacroCard(title: "Fat", current: foodStore.totalFat, goal: fatGoal, unit: "g", color: .red)
                    }

                    // Steps card
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Steps today")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text("\(stepService.steps)")
                                        .font(.system(size: 42, weight: .bold))
                                        .foregroundStyle(.purple)
                                    Text("/ \(stepGoal)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                HStack(spacing: 12) {
                                    if stepService.distance > 0 {
                                        Label(stepService.distanceKm, systemImage: "figure.walk")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if stepService.activeCalories > 0 {
                                        Label("\(Int(stepService.activeCalories)) kcal", systemImage: "flame.fill")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            Spacer()
                            RingView(progress: stepProgress, color: .purple)
                        }

                        ProgressView(value: stepProgress)
                            .tint(.purple)

                        if !stepService.isAvailable {
                            Text("Health data not available on this device")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if !stepService.isAuthorized {
                            Button {
                                stepService.requestAndStart()
                            } label: {
                                Text("Connect Apple Health")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(.purple)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding()
                    .background(.purple.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Quick stats
                    HStack(spacing: 12) {
                        QuickStat(
                            icon: "fork.knife",
                            value: "\(foodStore.loggedFoods.count)",
                            label: "Foods logged",
                            color: .green
                        )
                        QuickStat(
                            icon: "flame.fill",
                            value: "\(caloriesFromSteps)",
                            label: "kcal burned",
                            color: .orange
                        )
                        QuickStat(
                            icon: "figure.walk",
                            value: "\(stepsRemaining)",
                            label: "steps left",
                            color: .purple
                        )
                    }

                    // Today's meals summary
                    if !foodStore.loggedFoods.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Today's meals")
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            Divider().padding(.horizontal, 16)
                            ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { meal in
                                let mealFoods = foodStore.foods(for: meal)
                                if !mealFoods.isEmpty {
                                    HStack {
                                        Text(mealIcon(meal))
                                            .font(.title3)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(meal)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("\(mealFoods.count) item\(mealFoods.count == 1 ? "" : "s")")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text("\(foodStore.calories(for: meal)) kcal")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(mealColor(meal))
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
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.purple)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        stepService.fetchTodayData()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.purple)
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .environment(profileStore)
            }
        }
    }

    func mealIcon(_ meal: String) -> String {
        switch meal {
        case "Breakfast": return "🌅"
        case "Lunch": return "☀️"
        case "Dinner": return "🌙"
        case "Snack": return "🍎"
        default: return "🍽️"
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

// MARK: - Ring View

struct RingView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 8)
                .frame(width: 64, height: 64)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Macro Card

struct MacroCard: View {
    let title: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color

    var progress: Double {
        min(Double(current) / Double(goal), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(current)\(unit)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text("/ \(goal)\(unit)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            ProgressView(value: progress)
                .tint(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Quick Stat

struct QuickStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    DashboardView()
        .modelContainer(container)
        .environment(FoodStore(modelContext: container.mainContext))
}
