//
//  WorkoutView.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import Combine
import SwiftData
import AudioToolbox

// MARK: - Main Workout View

struct WorkoutView: View {
    @Environment(WorkoutStore.self) private var store
    @State private var selectedDayIndex: Int = 0
    @State private var showingSplitEditor = false
    @State private var showingStartWorkout = false
    @State private var showingActiveWorkout = false
    @State private var selectedSession: WorkoutSession? = nil
    @State private var retroactiveDate: Date? = nil

    var currentDayIndex: Int {
        switch Calendar.current.component(.weekday, from: .now) {
        case 1: return 6; case 2: return 0; case 3: return 1
        case 4: return 2; case 5: return 3; case 6: return 4
        case 7: return 5; default: return 0
        }
    }

    var selectedDay: SplitDay? {
        guard selectedDayIndex < store.splitDays.count else { return nil }
        return store.splitDays[selectedDayIndex]
    }

    var yesterdayIndex: Int { currentDayIndex == 0 ? 6 : currentDayIndex - 1 }

    var isMissedDay: Bool {
        guard yesterdayIndex < store.splitDays.count else { return false }
        let day = store.splitDays[yesterdayIndex]
        guard !day.isRestDay && !day.workoutName.isEmpty else { return false }
        return !store.hasSession(on: store.yesterday)
    }

    var isSelectedDayMissed: Bool { selectedDayIndex == yesterdayIndex && isMissedDay }

    var selectedDayExerciseNames: Set<String> { Set(selectedDay?.exercises.map(\.name) ?? []) }

    var dayPBs: [PersonalBest] {
        store.personalBests
            .filter { selectedDayExerciseNames.contains($0.exerciseName) }
            .sorted { $0.date > $1.date }
    }

    var daySessions: [WorkoutSession] {
        guard let day = selectedDay, !day.isRestDay else { return [] }
        if !day.workoutName.isEmpty {
            return store.completedSessions.filter {
                $0.name.lowercased() == day.workoutName.lowercased()
            }
        }
        return store.completedSessions
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if store.activeSession != nil { activeSessionBanner }
                    todayCard
                    weeklySplitCard
                    if !dayPBs.isEmpty { personalBestsCard }
                    if !(selectedDay?.isRestDay ?? false) { recentSessionsCard }
                }
                .padding()
            }
            .navigationTitle("Workout")
            .onAppear { selectedDayIndex = currentDayIndex }
            .sheet(isPresented: $showingSplitEditor) {
                SplitEditorView(store: store, selectedDayIndex: selectedDayIndex)
            }
            .sheet(isPresented: $showingStartWorkout) {
                StartWorkoutSheet(store: store, dayIndex: selectedDayIndex) {
                    showingStartWorkout = false
                    showingActiveWorkout = true
                }
            }
            .fullScreenCover(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView(store: store, isPresented: $showingActiveWorkout, retroactiveDate: $retroactiveDate)
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session, store: store)
            }
        }
    }

    // MARK: - Active Session Banner

    private var activeSessionBanner: some View {
        Button { showingActiveWorkout = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout in progress").font(.caption).foregroundStyle(.white.opacity(0.8))
                    Text(store.activeSession?.name ?? "").font(.headline).foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white)
            }
            .padding()
            .background(.purple)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Today Card

    private var todayCard: some View {
        Group {
            let days = store.splitDays
            if currentDayIndex < days.count {
                let todayPlan    = days[currentDayIndex]
                let todaySession = store.completedSessions.first { Calendar.current.isDateInToday($0.date) }
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Today — \(todayPlan.day)").font(.caption).foregroundStyle(.secondary)
                            if let session = todaySession {
                                Label("\(session.name) completed", systemImage: "checkmark.circle.fill")
                                    .font(.headline).foregroundStyle(.green)
                            } else {
                                Text(todayPlan.isRestDay ? "Rest Day" :
                                    todayPlan.workoutName.isEmpty ? "No workout planned" :
                                    todayPlan.workoutName).font(.headline)
                            }
                        }
                        Spacer()
                        if !todayPlan.isRestDay && store.activeSession == nil && todaySession == nil {
                            Button {
                                selectedDayIndex = currentDayIndex
                                showingStartWorkout = true
                            } label: {
                                Text("Start").font(.caption).fontWeight(.semibold).foregroundStyle(.white)
                                    .padding(.horizontal, 14).padding(.vertical, 7)
                                    .background(.purple).clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    if !todayPlan.isRestDay && !todayPlan.exercises.isEmpty {
                        ForEach(todayPlan.exercises.prefix(3)) { ex in
                            HStack(spacing: 6) {
                                Circle().fill(.purple.opacity(0.3)).frame(width: 6, height: 6)
                                Text(ex.name).font(.caption).foregroundStyle(.secondary)
                                Text("· \(ex.targetSets)×\(ex.targetReps)").font(.caption).foregroundStyle(.secondary.opacity(0.7))
                            }
                        }
                        if todayPlan.exercises.count > 3 {
                            Text("+ \(todayPlan.exercises.count - 3) more exercises").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(.purple.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Weekly Split Card

    private var weeklySplitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Split").font(.headline)
                Spacer()
                Button { showingSplitEditor = true } label: {
                    Text("Edit").font(.caption).foregroundStyle(.purple)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.splitDays.indices, id: \.self) { i in
                        let day        = store.splitDays[i]
                        let isSelected = i == selectedDayIndex
                        let isToday    = i == currentDayIndex
                        let isMissed   = i == yesterdayIndex && isMissedDay
                        Button { selectedDayIndex = i } label: {
                            VStack(spacing: 4) {
                                ZStack(alignment: .topTrailing) {
                                    Text(String(day.day.prefix(3))).font(.caption).fontWeight(.semibold)
                                    if isMissed {
                                        Circle().fill(.red).frame(width: 7, height: 7).offset(x: 6, y: -4)
                                    }
                                }
                                if day.isRestDay {
                                    Image(systemName: "moon.fill").font(.caption2).foregroundStyle(.orange)
                                } else {
                                    Text("\(day.exercises.count)").font(.caption2).fontWeight(.bold).foregroundStyle(.purple)
                                }
                                Circle().fill(isToday ? Color.purple : Color.clear).frame(width: 4, height: 4)
                            }
                            .frame(width: 52, height: 56)
                            .background(isSelected ? .purple.opacity(0.15) : .gray.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.purple : Color.clear, lineWidth: 1.5))
                            .foregroundStyle(isSelected ? .purple : .secondary)
                        }
                    }
                }
            }

            if let day = selectedDay {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(day.day).font(.subheadline).fontWeight(.semibold)
                                if isSelectedDayMissed {
                                    Text("Missed").font(.caption2).fontWeight(.semibold).foregroundStyle(.white)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(.red).clipShape(Capsule())
                                }
                            }
                            Text(day.isRestDay ? "Rest Day" :
                                day.workoutName.isEmpty ? "No workout planned" :
                                day.workoutName).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { showingSplitEditor = true } label: {
                            Text("Edit plan").font(.caption).foregroundStyle(.purple)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(.purple.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    if isSelectedDayMissed {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red).font(.caption)
                            Text("You missed this workout yesterday.").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                retroactiveDate = store.yesterday
                                showingStartWorkout = true
                            } label: {
                                Text("Log it").font(.caption).fontWeight(.semibold).foregroundStyle(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(.red).clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(10)
                        .background(.red.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    if day.isRestDay {
                        Label("Rest & recover", systemImage: "moon.fill").font(.caption).foregroundStyle(.secondary)
                    } else if day.exercises.isEmpty {
                        Text("No exercises added yet — tap Edit plan to set up this day.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(day.exercises) { ex in
                            HStack(spacing: 8) {
                                Circle().fill(.purple.opacity(0.3)).frame(width: 6, height: 6)
                                Text(ex.name).font(.caption).foregroundStyle(.primary)
                                Spacer()
                                Text("\(ex.targetSets)×\(ex.targetReps)").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(.purple.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Personal Bests Card

    private var personalBestsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Personal Bests").font(.headline)
                Spacer()
                Text(selectedDay?.day ?? "").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Divider().padding(.horizontal, 16)
            ForEach(dayPBs.prefix(5)) { pb in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pb.exerciseName).font(.subheadline).fontWeight(.medium)
                        Text(pb.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill").font(.caption).foregroundStyle(.yellow)
                        Text(pb.display).font(.subheadline).fontWeight(.semibold).foregroundStyle(.purple)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                Divider().padding(.horizontal, 16)
            }
        }
        .background(.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent Sessions Card

    private var recentSessionsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent Sessions").font(.headline)
                Spacer()
                Text(selectedDay?.workoutName.isEmpty == false ? selectedDay!.workoutName : "All sessions")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            if daySessions.isEmpty {
                Text("No sessions logged yet.")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 16).padding(.bottom, 12)
            } else {
                Divider().padding(.horizontal, 16)
                ForEach(daySessions.prefix(5)) { session in
                    Button { selectedSession = session } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.name).font(.subheadline).fontWeight(.medium).foregroundStyle(.primary)
                                Text("\(session.exercises.count) exercises · \(store.formatDuration(session.durationSeconds))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(session.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                    }
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .background(.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Split Editor

struct SplitEditorView: View {
    let store: WorkoutStore
    @State var selectedDayIndex: Int
    @State private var showingAddExercise = false
    @State private var showingCopyPlan = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.splitDays.indices, id: \.self) { i in
                            Button { selectedDayIndex = i } label: {
                                Text(String(store.splitDays[i].day.prefix(3)))
                                    .font(.caption).fontWeight(.semibold)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selectedDayIndex == i ? Color.purple : Color.gray.opacity(0.1))
                                    .foregroundStyle(selectedDayIndex == i ? .white : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding()
                }
                Divider()

                if selectedDayIndex < store.splitDays.count {
                    let day = store.splitDays[selectedDayIndex]
                    ScrollView {
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Workout name").font(.caption).foregroundStyle(.secondary)
                                TextField("e.g. Push A – Chest + Triceps", text: Binding(
                                    get: { day.workoutName },
                                    set: { day.workoutName = $0; store.saveSplitDay(day) }
                                ))
                                .textFieldStyle(.roundedBorder)
                            }

                            Toggle("Rest day", isOn: Binding(
                                get: { day.isRestDay },
                                set: { day.isRestDay = $0; store.saveSplitDay(day) }
                            ))
                            .tint(.purple)

                            if !day.isRestDay {
                                if store.splitDays.contains(where: { !$0.isRestDay && !$0.exercises.isEmpty }) {
                                    Button { showingCopyPlan = true } label: {
                                        Label("Copy plan from another day", systemImage: "doc.on.doc")
                                            .font(.subheadline).foregroundStyle(.blue)
                                            .frame(maxWidth: .infinity).padding()
                                            .background(.blue.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }

                                if !day.exercises.isEmpty {
                                    ForEach(day.exercises) { exercise in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(exercise.name).font(.subheadline).fontWeight(.medium)
                                                Text("\(exercise.targetSets) sets × \(exercise.targetReps) reps")
                                                    .font(.caption).foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Button {
                                                day.exercises.removeAll { $0.id == exercise.id }
                                                store.saveSplitDay(day)
                                            } label: {
                                                Image(systemName: "trash").font(.caption).foregroundStyle(.red.opacity(0.7))
                                            }
                                        }
                                        .padding()
                                        .background(.gray.opacity(0.07))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }

                                Button { showingAddExercise = true } label: {
                                    Label("Add exercise", systemImage: "plus.circle.fill")
                                        .font(.subheadline).foregroundStyle(.purple)
                                        .frame(maxWidth: .infinity).padding()
                                        .background(.purple.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Edit Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold).foregroundStyle(.purple)
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddSplitExerciseSheet { exercise in
                    if selectedDayIndex < store.splitDays.count {
                        let day = store.splitDays[selectedDayIndex]
                        day.exercises.append(exercise)
                        store.saveSplitDay(day)
                    }
                    showingAddExercise = false
                }
            }
            .sheet(isPresented: $showingCopyPlan) {
                CopyPlanSheet(store: store, currentDayIndex: selectedDayIndex) { sourceDayIndex in
                    let source = store.splitDays[sourceDayIndex]
                    let target = store.splitDays[selectedDayIndex]
                    target.exercises.append(contentsOf: source.exercises.map {
                        SplitExercise(name: $0.name, targetSets: $0.targetSets, targetReps: $0.targetReps)
                    })
                    if target.workoutName.isEmpty { target.workoutName = source.workoutName }
                    store.saveSplitDay(target)
                    showingCopyPlan = false
                }
            }
        }
    }
}

// MARK: - Copy Plan Sheet

struct CopyPlanSheet: View {
    let store: WorkoutStore
    let currentDayIndex: Int
    let onCopy: (Int) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.splitDays.indices, id: \.self) { i in
                    let day = store.splitDays[i]
                    if i != currentDayIndex && !day.isRestDay && !day.exercises.isEmpty {
                        Button { onCopy(i) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(day.day).font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
                                    Spacer()
                                    Text("\(day.exercises.count) exercises").font(.caption).foregroundStyle(.secondary)
                                }
                                if !day.workoutName.isEmpty {
                                    Text(day.workoutName).font(.caption).foregroundStyle(.purple)
                                }
                                Text(day.exercises.prefix(3).map(\.name).joined(separator: ", ") + (day.exercises.count > 3 ? "..." : ""))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Copy From")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(.red)
                }
            }
        }
    }
}

// MARK: - Add Split Exercise

struct AddSplitExerciseSheet: View {
    let onAdd: (SplitExercise) -> Void
    @State private var name = ""
    @State private var sets = "3"
    @State private var reps = "8-12"
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Exercise name").font(.caption).foregroundStyle(.secondary)
                    TextField("e.g. Flat Barbell Press", text: $name).textFieldStyle(.roundedBorder)
                }
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sets").font(.caption).foregroundStyle(.purple)
                        TextField("3", text: $sets).textFieldStyle(.roundedBorder).keyboardType(.numberPad)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Target reps").font(.caption).foregroundStyle(.blue)
                        TextField("8-12", text: $reps).textFieldStyle(.roundedBorder)
                    }
                }
                Button {
                    onAdd(SplitExercise(name: name, targetSets: Int(sets) ?? 3, targetReps: reps))
                } label: {
                    Text("Add").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(name.isEmpty ? .gray : .purple)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(name.isEmpty)
                Spacer()
            }
            .padding()
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(.red)
                }
            }
        }
    }
}

// MARK: - Start Workout Sheet

struct StartWorkoutSheet: View {
    let store: WorkoutStore
    let dayIndex: Int
    let onStart: () -> Void
    @State private var workoutName = ""
    @Environment(\.dismiss) var dismiss

    var dayPlan: SplitDay? {
        guard dayIndex < store.splitDays.count else { return nil }
        return store.splitDays[dayIndex]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Workout name").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. Push A", text: $workoutName).textFieldStyle(.roundedBorder)
                    }
                    .onAppear { workoutName = dayPlan?.workoutName ?? "" }

                    if let exercises = dayPlan?.exercises, !exercises.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Exercises from split").font(.caption).foregroundStyle(.secondary)
                            ForEach(exercises) { ex in
                                HStack {
                                    Text(ex.name).font(.subheadline)
                                    Spacer()
                                    Text("\(ex.targetSets)×\(ex.targetReps)").font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(.gray.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }

                    Button {
                        if let plan = dayPlan, !plan.exercises.isEmpty {
                            store.startSession(name: workoutName, exercises: plan.exercises)
                        } else {
                            store.startEmptySession(name: workoutName)
                        }
                        dismiss()
                        onStart()
                    } label: {
                        Text("Start Workout").font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(workoutName.isEmpty ? .gray : .purple)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(workoutName.isEmpty)
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(.red)
                }
            }
        }
    }
}

// MARK: - Active Workout

struct ActiveWorkoutView: View {
    let store: WorkoutStore
    @Binding var isPresented: Bool
    @Binding var retroactiveDate: Date?
    @State private var showingAddExercise = false
    @State private var showingFinishConfirm = false
    @State private var showingCancelConfirm = false
    @State private var restTimerSeconds = 0
    @State private var restTimerRunning = false
    @State private var selectedRestTime = 90
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let restOptions = [30, 60, 90, 120, 180]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // Rest timer row — only shown while rest timer is active
                        if restTimerRunning { restTimerRow }

                        if let session = store.activeSession {
                            ForEach(session.exercises.indices, id: \.self) { i in
                                ExerciseLogCard(
                                    store: store, exerciseIndex: i,
                                    onSetCompleted: {
                                        startRestTimer()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("input_\(i)", anchor: .bottom) }
                                        }
                                    },
                                    onFocused: {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                            withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("input_\(i)", anchor: .bottom) }
                                        }
                                    }
                                )
                                .id("exercise_\(i)")
                            }
                        }

                        // Rest timer trigger — always visible, lets user start manually too
                        Menu {
                            ForEach(restOptions, id: \.self) { sec in
                                Button("\(sec)s rest") { selectedRestTime = sec; startRestTimer() }
                            }
                        } label: {
                            Label("Start rest timer", systemImage: "timer")
                                .font(.subheadline).foregroundStyle(.orange)
                                .frame(maxWidth: .infinity).padding()
                                .background(.orange.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button { showingAddExercise = true } label: {
                            Label("Add exercise", systemImage: "plus.circle.fill")
                                .font(.subheadline).foregroundStyle(.purple)
                                .frame(maxWidth: .infinity).padding()
                                .background(.purple.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button { showingFinishConfirm = true } label: {
                            Text("Finish Workout").font(.headline).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).padding()
                                .background(.purple).clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Color.clear.frame(height: 350)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(retroactiveDate != nil ? "Log Yesterday's Workout" : (store.activeSession?.name ?? "Workout"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingCancelConfirm = true }.foregroundStyle(.red)
                }
            }
            .onReceive(timer) { _ in
                guard restTimerRunning else { return }
                if restTimerSeconds > 1 {
                    restTimerSeconds -= 1
                } else {
                    // Timer just hit zero — fire all three alerts
                    restTimerSeconds = 0
                    restTimerRunning = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    AudioServicesPlaySystemSound(1005) // Received message sound
                    NotificationManager.shared.cancelRestTimer() // already fired via system
                }
            }
            .alert("Finish Workout?", isPresented: $showingFinishConfirm) {
                Button("Finish", role: .destructive) { store.finishSession(on: retroactiveDate); isPresented = false }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(retroactiveDate != nil ? "This will be saved as yesterday's session." : "This will save your session and update personal bests.")
            }
            .alert("Cancel Workout?", isPresented: $showingCancelConfirm) {
                Button("Discard", role: .destructive) { store.cancelSession(); retroactiveDate = nil; isPresented = false }
                Button("Keep going", role: .cancel) {}
            } message: { Text("Your workout progress will be lost.") }
            .sheet(isPresented: $showingAddExercise) {
                AddSplitExerciseSheet { ex in
                    store.activeSession?.exercises.append(ActiveExercise(name: ex.name, targetSets: ex.targetSets, targetReps: ex.targetReps))
                    showingAddExercise = false
                }
            }
        }
    }

    // MARK: - Rest Timer Row (shown only when running)
    private var restTimerRow: some View {
        HStack {
            Spacer()
            VStack(spacing: 2) {
                Text(formatTime(restTimerSeconds))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(restTimerSeconds <= 10 ? .red : .orange)
                Text("rest remaining").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                restTimerRunning = false
                restTimerSeconds = 0
                NotificationManager.shared.cancelRestTimer()
            } label: {
                Text("Skip")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.gray.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.orange.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: restTimerRunning)
    }

    func startRestTimer() {
        restTimerSeconds = selectedRestTime
        restTimerRunning = true
        NotificationManager.shared.scheduleRestTimer(seconds: selectedRestTime)
    }
    func formatTime(_ s: Int) -> String { String(format: "%d:%02d", s / 60, s % 60) }
}

// MARK: - Exercise Log Card

struct ExerciseLogCard: View {
    let store: WorkoutStore
    let exerciseIndex: Int
    let onSetCompleted: () -> Void
    let onFocused: () -> Void

    @State private var weightInput = ""
    @State private var repsInput = ""
    @State private var isWarmup = false
    @FocusState private var weightFocused: Bool
    @FocusState private var repsFocused: Bool

    var exercise: ActiveExercise? { store.activeSession?.exercises[exerciseIndex] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(exercise?.name ?? "").font(.headline)
                    Spacer()
                    if let pb = store.pb(for: exercise?.name ?? "") {
                        Label("PB: \(pb.display)", systemImage: "trophy.fill").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text("Target: \(exercise?.targetSets ?? 0) sets × \(exercise?.targetReps ?? "") reps")
                    .font(.caption).foregroundStyle(.secondary)

                let lastSets = store.lastSets(for: exercise?.name ?? "").filter { !$0.isWarmup }
                if !lastSets.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            Text("Last:").font(.caption2).foregroundStyle(.secondary)
                            ForEach(lastSets) { set in
                                Text("\(String(format: "%g", set.weight))kg×\(set.reps)")
                                    .font(.caption2).padding(.horizontal, 6).padding(.vertical, 3)
                                    .background(.blue.opacity(0.1)).foregroundStyle(.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)

            if let sets = exercise?.sets, !sets.isEmpty {
                Divider().padding(.horizontal, 16)
                HStack {
                    Text("Set").font(.caption).foregroundStyle(.secondary).frame(width: 30)
                    Text("Weight").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    Text("Reps").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    Text("Type").font(.caption).foregroundStyle(.secondary).frame(width: 64)
                    Spacer().frame(width: 24)
                }
                .padding(.horizontal, 16).padding(.vertical, 6)

                ForEach(sets.indices, id: \.self) { i in
                    let set = sets[i]
                    HStack {
                        Text("\(i + 1)").font(.caption).foregroundStyle(.secondary).frame(width: 30)
                        Text("\(String(format: "%g", set.weight))kg").font(.subheadline).fontWeight(.medium).frame(maxWidth: .infinity)
                        Text("\(set.reps)").font(.subheadline).fontWeight(.medium).frame(maxWidth: .infinity)
                        Text(set.isWarmup ? "Warmup" : "Working").font(.caption2)
                            .foregroundStyle(set.isWarmup ? .orange : .purple).frame(width: 64)
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).frame(width: 24)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(set.isWarmup ? Color.orange.opacity(0.04) : Color.green.opacity(0.04))
                    Divider().padding(.horizontal, 16)
                }
            }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weight (kg)").font(.caption2).foregroundStyle(.secondary)
                        TextField("0", text: $weightInput).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                            .focused($weightFocused)
                            .onChange(of: weightFocused) { _, focused in if focused { onFocused() } }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reps").font(.caption2).foregroundStyle(.secondary)
                        TextField("0", text: $repsInput).textFieldStyle(.roundedBorder).keyboardType(.numberPad)
                            .focused($repsFocused)
                            .onChange(of: repsFocused) { _, focused in if focused { onFocused() } }
                    }
                }
                HStack {
                    Toggle("Warmup", isOn: $isWarmup).font(.caption).tint(.orange)
                    Spacer()
                    Button { addSet() } label: {
                        Text("+ Log Set").font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background((weightInput.isEmpty || repsInput.isEmpty) ? Color.gray : Color.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(weightInput.isEmpty || repsInput.isEmpty)
                }
            }
            .padding(16)
            .id("input_\(exerciseIndex)")
        }
        .background(.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func addSet() {
        guard let weight = Double(weightInput), let reps = Int(repsInput), let session = store.activeSession else { return }
        session.exercises[exerciseIndex].sets.append(LoggedSet(weight: weight, reps: reps, isWarmup: isWarmup, completed: true))
        weightInput = ""; repsInput = ""
        if !isWarmup { onSetCompleted() }
        isWarmup = false
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    let session: WorkoutSession
    let store: WorkoutStore
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteConfirm = false

    var totalVolumeDisplay: String {
        let vol = session.exercises.reduce(0.0) { $0 + $1.totalVolume }
        return vol >= 1000 ? String(format: "%.1ft", vol / 1000) : "\(Int(vol))kg"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 0) {
                        StatBox(value: store.formatDuration(session.durationSeconds), label: "Duration")
                        Divider().frame(height: 40)
                        StatBox(value: "\(session.exercises.count)", label: "Exercises")
                        Divider().frame(height: 40)
                        StatBox(value: "\(session.exercises.reduce(0) { $0 + $1.sets.count })", label: "Total sets")
                        Divider().frame(height: 40)
                        StatBox(value: totalVolumeDisplay, label: "Volume")
                    }
                    .padding(.vertical, 12)
                    .background(.purple.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    ForEach(session.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(exercise.name).font(.headline)
                                    Spacer()
                                    if let pb = store.pb(for: exercise.name),
                                       let best = exercise.bestSet,
                                       best.weight * Double(best.reps) >= pb.weight * Double(pb.reps) {
                                        Label("New PB!", systemImage: "trophy.fill").font(.caption).foregroundStyle(.yellow)
                                    }
                                }
                                HStack(spacing: 12) {
                                    Text("\(exercise.sets.filter { !$0.isWarmup }.count) working sets").font(.caption).foregroundStyle(.secondary)
                                    if !exercise.sets.filter({ $0.isWarmup }).isEmpty {
                                        Text("\(exercise.sets.filter { $0.isWarmup }.count) warmup").font(.caption).foregroundStyle(.orange.opacity(0.8))
                                    }
                                    Text("Vol: \(Int(exercise.totalVolume))kg").font(.caption).foregroundStyle(.purple)
                                }
                            }
                            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)

                            if !exercise.sets.isEmpty {
                                Divider().padding(.horizontal, 16)
                                HStack {
                                    Text("Set").font(.caption).foregroundStyle(.secondary).frame(width: 30)
                                    Text("Weight").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                                    Text("Reps").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                                    Text("Volume").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                                    Text("Type").font(.caption).foregroundStyle(.secondary).frame(width: 60)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 6)

                                ForEach(exercise.sets.indices, id: \.self) { i in
                                    let set    = exercise.sets[i]
                                    let isBest = !set.isWarmup && exercise.bestSet?.id == set.id
                                    HStack {
                                        Text("\(i + 1)").font(.caption).foregroundStyle(.secondary).frame(width: 30)
                                        Text("\(String(format: "%g", set.weight))kg").font(.subheadline).fontWeight(.medium).frame(maxWidth: .infinity)
                                        Text("\(set.reps)").font(.subheadline).fontWeight(.medium).frame(maxWidth: .infinity)
                                        HStack(spacing: 2) {
                                            Text("\(Int(set.weight * Double(set.reps)))kg")
                                                .font(.subheadline).fontWeight(isBest ? .semibold : .regular)
                                                .foregroundStyle(isBest ? .purple : .primary)
                                            if isBest { Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(.purple) }
                                        }
                                        .frame(maxWidth: .infinity)
                                        Text(set.isWarmup ? "Warmup" : "Working").font(.caption2)
                                            .foregroundStyle(set.isWarmup ? .orange : .purple).frame(width: 60)
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                                    .background(set.isWarmup ? Color.orange.opacity(0.04) : isBest ? Color.purple.opacity(0.06) : Color.clear)
                                    Divider().padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(.gray.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    if !session.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes").font(.headline)
                            Text(session.notes).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.gray.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle(session.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash").foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(.purple)
                }
            }
            .alert("Delete Session?", isPresented: $showingDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    store.deleteSession(session)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete \"\(session.name)\" and cannot be undone.")
            }
        }
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.subheadline).fontWeight(.semibold).foregroundStyle(.purple)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkoutSession.self, SplitDay.self, PersonalBest.self,
        configurations: config
    )
    WorkoutView()
        .modelContainer(container)
        .environment(WorkoutStore(modelContext: container.mainContext))
}
