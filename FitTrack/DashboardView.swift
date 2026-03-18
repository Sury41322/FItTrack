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
    private let pedometer   = CMPedometer()

    @Published var steps: Int             = 0
    @Published var distance: Double       = 0
    @Published var activeCalories: Double = 0
    @Published var isAvailable: Bool      = false
    @Published var isAuthorized: Bool     = false

    private var observerQueries: [HKObserverQuery] = []

    init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
        if isAvailable { requestAndStart() }
    }

    func requestAndStart() {
        guard
            let stepType     = HKQuantityType.quantityType(forIdentifier: .stepCount),
            let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
            let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        else { return }

        healthStore.requestAuthorization(toShare: nil, read: [stepType, distanceType, caloriesType]) { success, _ in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchTodayData()
                    self.startObserver(for: .activeEnergyBurned) { self.fetchActiveCalories() }
                }
            }
        }

        if CMMotionActivityManager.isActivityAvailable() {
            let manager = CMMotionActivityManager()
            manager.startActivityUpdates(to: .main) { _ in }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                manager.stopActivityUpdates()
                self.startPedometerUpdates()
            }
        }
    }

    private func startPedometerUpdates() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: Calendar.current.startOfDay(for: .now)) { [weak self] data, error in
            guard let data, error == nil else { return }
            DispatchQueue.main.async {
                self?.steps    = data.numberOfSteps.intValue
                self?.distance = data.distance?.doubleValue ?? 0
            }
        }
    }

    private func startObserver(for identifier: HKQuantityTypeIdentifier, onUpdate: @escaping () -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { _, _ in }
        let query = HKObserverQuery(sampleType: type, predicate: nil) { _, done, error in
            guard error == nil else { done(); return }
            onUpdate()
            done()
        }
        healthStore.execute(query)
        observerQueries.append(query)
    }

    func fetchTodayData() { fetchActiveCalories() }

    private func fetchActiveCalories() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let start = Calendar.current.startOfDay(for: .now)
        let pred  = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .cumulativeSum) { _, result, _ in
            DispatchQueue.main.async {
                self.activeCalories = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            }
        }
        healthStore.execute(query)
    }

    var distanceKm: String { String(format: "%.2f km", distance / 1000) }

    /// Fetches daily step totals for a date range using HKStatisticsCollectionQuery.
    /// Returns a dict of [startOfDay: stepCount] — one entry per day that had steps.
    func fetchStepsForDateRange(
        from startDate: Date,
        to endDate: Date,
        completion: @escaping ([Date: Int]) -> Void
    ) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion([:]); return
        }
        let pred        = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let interval    = DateComponents(day: 1)
        let anchorDate  = Calendar.current.startOfDay(for: startDate)

        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: pred,
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        query.initialResultsHandler = { _, results, _ in
            var stepsByDate: [Date: Int] = [:]
            results?.enumerateStatistics(from: startDate, to: endDate) { stats, _ in
                let day   = Calendar.current.startOfDay(for: stats.startDate)
                let steps = Int(stats.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                if steps > 0 { stepsByDate[day] = steps }
            }
            DispatchQueue.main.async { completion(stepsByDate) }
        }
        healthStore.execute(query)
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @Environment(DayLogStore.self)  var dayLogStore
    @Environment(FoodStore.self)    var foodStore
    @Environment(ProfileStore.self) var profileStore
    @Environment(WeightStore.self)  var weightStore
    @Environment(WorkoutStore.self) var workoutStore
    @StateObject private var stepService = StepCounterService()
    @State private var showingProfile = false
    @Environment(\.scenePhase) private var scenePhase
    let snapshotTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    // TODO: move macro goals to UserProfile
    let proteinGoal = 150
    let carbsGoal   = 200
    let fatGoal     = 65

    var calorieGoal: Int        { profileStore.calorieGoal }
    var stepGoal: Int           { profileStore.stepGoal }
    var calorieProgress: Double { min(Double(foodStore.totalCalories) / Double(calorieGoal), 1.0) }
    var stepProgress: Double    { min(Double(stepService.steps) / Double(stepGoal), 1.0) }
    var caloriesFromSteps: Int  { Int(Double(stepService.steps) * 0.04) }
    var stepsRemaining: Int     { max(0, stepGoal - stepService.steps) }

    /// Workout weekdays derived from the active split.
    /// Uses the same index mapping as `currentDayIndex` (Mon=0 → weekday 2, …, Sun=6 → weekday 1).
    private var workoutWeekdays: Set<Int> {
        // splitDays is indexed Mon–Sun (0–6); Calendar weekday is Sun=1, Mon=2…Sat=7.
        let calendarOffset = [2, 3, 4, 5, 6, 7, 1] // splitIndex 0…6 → Calendar weekday
        return Set(
            workoutStore.splitDays.enumerated()
                .filter { !$0.element.isRestDay }
                .map    {  calendarOffset[$0.offset] }
        )
    }

    var currentDayIndex: Int {
        switch Calendar.current.component(.weekday, from: .now) {
        case 1: return 6; case 2: return 0; case 3: return 1
        case 4: return 2; case 5: return 3; case 6: return 4
        case 7: return 5; default: return 0
        }
    }

    var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    greetingHeader
                    activityCalendarCard
                    caloriesCard
                    macrosRow
                    stepsCard
                    weightTrendCard

                    // ── Workout Reminder Banner ──────────────────────────────
                    WorkoutReminderBannerView(workoutWeekdays: workoutWeekdays)
                    // ────────────────────────────────────────────────────────

                    quickStats
                    if !foodStore.loggedFoods.isEmpty { mealsSection }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .onAppear {
                snapshotToday()
                backfillAllHistory()
                // Sync notifications whenever the dashboard appears
                // (handles split edits made in the Workout tab).
                Task {
                    await NotificationManager.shared.reschedule(workoutWeekdays: workoutWeekdays)
                }
            }
            .onReceive(snapshotTimer) { _ in
                snapshotToday()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    stepService.fetchTodayData()
                    snapshotToday()
                }
            }
            .onChange(of: stepService.steps)       { _, _ in snapshotToday() }
            .onChange(of: foodStore.totalProtein)  { _, _ in snapshotToday() }
            .onChange(of: foodStore.totalCalories) { _, _ in snapshotToday() }
            // Re-schedule whenever the split changes mid-session
            .onChange(of: workoutStore.splitDays) { _, _ in
                Task {
                    await NotificationManager.shared.reschedule(workoutWeekdays: workoutWeekdays)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        stepService.fetchTodayData()
                        snapshotToday()
                    } label: {
                        Image(systemName: "arrow.clockwise").foregroundStyle(.purple)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingProfile = true } label: {
                        Image(systemName: "gearshape.fill").foregroundStyle(.purple)
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView().environment(profileStore)
            }
        }
    }

    // MARK: - Snapshot

    private func snapshotToday() {
        let todayWorkout = workoutStore.completedSessions.contains {
            Calendar.current.isDateInToday($0.date)
        }
        let todayIsRest = currentDayIndex < workoutStore.splitDays.count
            ? workoutStore.splitDays[currentDayIndex].isRestDay
            : false

        dayLogStore.snapshotToday(
            steps:         stepService.steps,
            calories:      foodStore.totalCalories,
            protein:       foodStore.totalProtein,
            workoutLogged: todayWorkout,
            isRestDay:     todayIsRest
        )
    }

    private func backfillAllHistory() {
        guard !dayLogStore.hasBackfilledHistory else { return }
        let end   = Calendar.current.startOfDay(for: .now)
        let start = Calendar.current.date(byAdding: .month, value: -6, to: end)!
        stepService.fetchStepsForDateRange(from: start, to: end) { stepsByDate in
            dayLogStore.backfillSteps(stepsByDate)
        }
    }

    // MARK: - Cards

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting).font(.subheadline).foregroundStyle(.secondary)
                Text(profileStore.name.isEmpty
                     ? "Here's your day"
                     : "Hey, \(profileStore.name.split(separator: " ").first.map(String.init) ?? profileStore.name) 👋")
                    .font(.title2).fontWeight(.semibold)
            }
            Spacer()
            Text(Date().formatted(date: .abbreviated, time: .omitted))
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var caloriesCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calories today").font(.subheadline).foregroundStyle(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(foodStore.totalCalories)")
                            .font(.system(size: 42, weight: .bold)).foregroundStyle(.green)
                        Text("/ \(calorieGoal) kcal").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                RingView(progress: calorieProgress, color: .green)
            }
            ProgressView(value: calorieProgress).tint(.green)
        }
        .padding()
        .background(.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var macrosRow: some View {
        HStack(spacing: 12) {
            MacroCard(title: "Protein", current: foodStore.totalProtein, goal: proteinGoal, unit: "g", color: .blue)
            MacroCard(title: "Carbs",   current: foodStore.totalCarbs,   goal: carbsGoal,   unit: "g", color: .orange)
            MacroCard(title: "Fat",     current: foodStore.totalFat,     goal: fatGoal,     unit: "g", color: .red)
        }
    }

    private var stepsCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Steps today").font(.subheadline).foregroundStyle(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(stepService.steps)")
                            .font(.system(size: 42, weight: .bold)).foregroundStyle(.purple)
                        Text("/ \(stepGoal)").font(.subheadline).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 12) {
                        if stepService.distance > 0 {
                            Label(stepService.distanceKm, systemImage: "figure.walk")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if stepService.activeCalories > 0 {
                            Label("\(Int(stepService.activeCalories)) kcal", systemImage: "flame.fill")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
                Spacer()
                RingView(progress: stepProgress, color: .purple)
            }
            ProgressView(value: stepProgress).tint(.purple)
            if !stepService.isAvailable {
                Text("Health data not available on this device")
                    .font(.caption).foregroundStyle(.secondary)
            } else if !stepService.isAuthorized {
                Button { stepService.requestAndStart() } label: {
                    Text("Connect Apple Health")
                        .font(.caption).fontWeight(.semibold).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(.purple).clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(.purple.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var weightTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weight trend").font(.headline)
                    if let latest = weightStore.latestEntry {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(String(format: "%g", latest.weightKg))
                                .font(.system(size: 32, weight: .bold)).foregroundStyle(.teal)
                            Text("kg").font(.subheadline).foregroundStyle(.secondary)
                            Text(latest.mood.emoji).font(.title3)
                        }
                    } else {
                        Text("No data yet").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let latest = weightStore.latestEntry {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(latest.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption).foregroundStyle(.secondary)
                        if let delta = weightDelta {
                            HStack(spacing: 2) {
                                Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                                Text(String(format: "%.1f kg", abs(delta)))
                            }
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(delta >= 0 ? .orange : .teal)
                        }
                    }
                }
            }
            if weightStore.last7Days.count >= 2 {
                WeightChartView(entries: weightStore.last7Days).frame(height: 100)
            } else {
                Text("Log at least 2 days to see your trend")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 20)
            }
        }
        .padding()
        .background(.teal.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var weightDelta: Double? {
        let entries = weightStore.last7Days
        guard entries.count >= 2 else { return nil }
        return entries.last!.weightKg - entries[entries.count - 2].weightKg
    }

    private var activityCalendarCard: some View {
        ActivityCalendarView(stepGoal: stepGoal, proteinGoal: proteinGoal)
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            QuickStat(icon: "fork.knife",  value: "\(foodStore.loggedFoods.count)", label: "Foods logged", color: .green)
            QuickStat(icon: "flame.fill",  value: "\(caloriesFromSteps)",           label: "kcal burned",  color: .orange)
            QuickStat(icon: "figure.walk", value: "\(stepsRemaining)",              label: "steps left",   color: .purple)
        }
    }

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Today's meals").font(.headline)
                .padding(.horizontal, 16).padding(.vertical, 12)
            Divider().padding(.horizontal, 16)
            ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { meal in
                let foods = foodStore.foods(for: meal)
                if !foods.isEmpty {
                    HStack {
                        Text(mealIcon(meal)).font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(meal).font(.subheadline).fontWeight(.medium)
                            Text("\(foods.count) item\(foods.count == 1 ? "" : "s")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(foodStore.calories(for: meal)) kcal")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(mealColor(meal))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .background(.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    func mealIcon(_ meal: String) -> String {
        switch meal {
        case "Breakfast": return "🌅"
        case "Lunch":     return "☀️"
        case "Dinner":    return "🌙"
        case "Snack":     return "🍎"
        default:          return "🍽️"
        }
    }

    func mealColor(_ meal: String) -> Color {
        switch meal {
        case "Breakfast": return .orange
        case "Lunch":     return .yellow
        case "Dinner":    return .indigo
        case "Snack":     return .green
        default:          return .gray
        }
    }
}

// MARK: - Weight Chart

struct WeightChartView: View {
    let entries: [WeightEntry]

    private var weights: [Double] { entries.map(\.weightKg) }
    private var minW: Double  { (weights.min() ?? 0) - 1 }
    private var maxW: Double  { (weights.max() ?? 1) + 1 }
    private var range: Double { max(maxW - minW, 1) }

    var body: some View {
        GeometryReader { geo in
            let w     = geo.size.width
            let h     = geo.size.height
            let count = entries.count
            let step  = w / CGFloat(count - 1)
            ZStack {
                Path { path in
                    let pts = points(count: count, step: step, h: h)
                    path.move(to: CGPoint(x: pts[0].x, y: h))
                    path.addLine(to: pts[0])
                    for pt in pts.dropFirst() { path.addLine(to: pt) }
                    path.addLine(to: CGPoint(x: pts.last!.x, y: h))
                    path.closeSubpath()
                }
                .fill(.teal.opacity(0.15))

                Path { path in
                    let pts = points(count: count, step: step, h: h)
                    path.move(to: pts[0])
                    for pt in pts.dropFirst() { path.addLine(to: pt) }
                }
                .stroke(.teal, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                ForEach(entries.indices, id: \.self) { i in
                    let pt = point(i: i, step: step, h: h)
                    Circle().fill(.teal).frame(width: 6, height: 6).position(pt)
                    Text(dayLabel(entries[i].date))
                        .font(.system(size: 9)).foregroundStyle(.secondary)
                        .position(x: pt.x, y: h + 12)
                }

                if let last = entries.last {
                    let pt = point(i: entries.count - 1, step: step, h: h)
                    Text(String(format: "%g", last.weightKg))
                        .font(.system(size: 10, weight: .semibold)).foregroundStyle(.teal)
                        .position(x: pt.x, y: max(pt.y - 12, 10))
                }
            }
            .padding(.bottom, 16)
        }
    }

    private func points(count: Int, step: CGFloat, h: CGFloat) -> [CGPoint] {
        entries.indices.map { point(i: $0, step: step, h: h) }
    }

    private func point(i: Int, step: CGFloat, h: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(i) * step,
            y: CGFloat(1 - (weights[i] - minW) / range) * (h - 16)
        )
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "E"
        return String(f.string(from: date).prefix(2))
    }
}

// MARK: - Ring View

struct RingView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: 8).frame(width: 64, height: 64)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            Text("\(Int(progress * 100))%")
                .font(.caption2).fontWeight(.semibold).foregroundStyle(color)
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

    var progress: Double { min(Double(current) / Double(goal), 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("\(current)\(unit)").font(.title3).fontWeight(.semibold).foregroundStyle(color)
            Text("/ \(goal)\(unit)").font(.caption2).foregroundStyle(.secondary)
            ProgressView(value: progress).tint(color)
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
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text(value).font(.subheadline).fontWeight(.semibold).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FoodEntry.self, UserProfile.self, WeightEntry.self, DayLog.self,
        configurations: config
    )
    DashboardView()
        .modelContainer(container)
        .environment(FoodStore(modelContext: container.mainContext))
        .environment(ProfileStore(modelContext: container.mainContext))
        .environment(WeightStore(modelContext: container.mainContext))
        .environment(WorkoutStore(modelContext: container.mainContext))
        .environment(DayLogStore(modelContext: container.mainContext))
}
