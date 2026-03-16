//
//  WorkoutView.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import Combine
import SwiftData
// MARK: - Main Workout View

struct WorkoutView: View {
    @Environment(WorkoutStore.self) private var store
    @State private var selectedDayIndex: Int = 0
    @State private var showingSplitEditor = false
    @State private var showingStartWorkout = false
    @State private var showingActiveWorkout = false
    @State private var selectedSession: WorkoutSession? = nil

    var currentDayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // weekday: 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
        // dayOrder: 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri, 5=Sat, 6=Sun
        switch weekday {
        case 1: return 6 // Sun
        case 2: return 0 // Mon
        case 3: return 1 // Tue
        case 4: return 2 // Wed
        case 5: return 3 // Thu
        case 6: return 4 // Fri
        case 7: return 5 // Sat
        default: return 0
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Active session banner
                    if store.activeSession != nil {
                        Button {
                            showingActiveWorkout = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Workout in progress")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                    Text(store.activeSession?.name ?? "")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.white)
                            }
                            .padding()
                            .background(.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    // Today card
                    let days = store.splitDays
                    if currentDayIndex < days.count {
                        let todayPlan = days[currentDayIndex]
                        let todaySession = store.completedSessions.first {
                            Calendar.current.isDateInToday($0.date)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Today — \(todayPlan.day)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let session = todaySession {
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                                .font(.subheadline)
                                            Text("\(session.name) completed")
                                                .font(.headline)
                                                .foregroundStyle(.green)
                                        }
                                    } else {
                                        Text(todayPlan.isRestDay ? "Rest Day" : (todayPlan.workoutName.isEmpty ? "No workout planned" : todayPlan.workoutName))
                                            .font(.headline)
                                    }
                                }
                                Spacer()
                                if !todayPlan.isRestDay && store.activeSession == nil && todaySession == nil {
                                    Button {
                                        selectedDayIndex = currentDayIndex
                                        showingStartWorkout = true
                                    } label: {
                                        Text("Start")
                                           .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(.purple)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            if !todayPlan.isRestDay && !todayPlan.exercises.isEmpty {
                                ForEach(todayPlan.exercises.prefix(3)) { ex in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(.purple.opacity(0.3))
                                            .frame(width: 6, height: 6)
                                        Text(ex.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("· \(ex.targetSets)×\(ex.targetReps)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary.opacity(0.7))
                                    }
                                }
                                if todayPlan.exercises.count > 3 {
                                    Text("+ \(todayPlan.exercises.count - 3) more exercises")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(.purple.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Weekly split
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Weekly Split").font(.headline)
                            Spacer()
                            Button {
                                showingSplitEditor = true
                            } label: {
                                Text("Edit").font(.caption).foregroundStyle(.purple)
                            }
                        }

                        // Day strip
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(store.splitDays.indices, id: \.self) { i in
                                    let day = store.splitDays[i]
                                    Button {
                                        selectedDayIndex = i
                                    } label: {
                                        VStack(spacing: 6) {
                                            Text(String(day.day.prefix(3)))
                                                .font(.caption).fontWeight(.semibold)
                                            if day.isRestDay {
                                                Image(systemName: "moon.fill")
                                                    .font(.caption2).foregroundStyle(.orange)
                                            } else {
                                                Text("\(day.exercises.count)")
                                                    .font(.caption2).fontWeight(.bold).foregroundStyle(.purple)
                                            }
                                        }
                                        .frame(width: 52, height: 52)
                                        .background(i == selectedDayIndex ? .purple.opacity(0.15) : .gray.opacity(0.07))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(i == selectedDayIndex ? Color.purple : Color.clear, lineWidth: 1.5))
                                        .foregroundStyle(i == selectedDayIndex ? .purple : .secondary)
                                    }
                                }
                            }
                        }

                        // Selected day plan
                        let selectedDay = store.splitDays[selectedDayIndex]
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedDay.day).font(.subheadline).fontWeight(.semibold)
                                    Text(selectedDay.isRestDay ? "Rest Day" : (selectedDay.workoutName.isEmpty ? "No workout planned" : selectedDay.workoutName))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    showingSplitEditor = true
                                } label: {
                                    Text("Edit plan")
                                        .font(.caption)
                                        .foregroundStyle(.purple)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(.purple.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }

                            if selectedDay.isRestDay {
                                HStack(spacing: 8) {
                                    Image(systemName: "moon.fill").foregroundStyle(.orange)
                                    Text("Rest & recover").font(.caption).foregroundStyle(.secondary)
                                }
                            } else if selectedDay.exercises.isEmpty {
                                Text("No exercises added yet — tap Edit plan to set up this day.")
                                    .font(.caption).foregroundStyle(.secondary)
                            } else {
                                ForEach(selectedDay.exercises) { ex in
                                    HStack(spacing: 8) {
                                        Circle().fill(.purple.opacity(0.3)).frame(width: 6, height: 6)
                                        Text(ex.name).font(.caption).foregroundStyle(.primary)
                                        Spacer()
                                        Text("\(ex.targetSets)×\(ex.targetReps)")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(.purple.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()
                    .background(.gray.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Personal bests
                    if !store.personalBests.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Personal Bests")
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            Divider().padding(.horizontal, 16)
                            ForEach(store.personalBests
                                .sorted { $0.date > $1.date }
                                .prefix(5)) { pb in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(pb.exerciseName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(pb.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "trophy.fill")
                                            .font(.caption)
                                            .foregroundStyle(.yellow)
                                        Text(pb.display)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.purple)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                Divider().padding(.horizontal, 16)
                            }
                        }
                        .background(.gray.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Recent sessions
                    if !store.completedSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Recent Sessions")
                                .font(.headline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            Divider().padding(.horizontal, 16)
                            ForEach(store.completedSessions.prefix(5)) { session in
                                Button {
                                    selectedSession = session
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(session.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.primary)
                                            Text("\(session.exercises.count) exercises · \(store.formatDuration(session.durationSeconds))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                                Divider().padding(.horizontal, 16)
                            }
                        }
                        .background(.gray.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle("Workout")
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
                ActiveWorkoutView(store: store, isPresented: $showingActiveWorkout)
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session, store: store)
            }
        }
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
                // Day picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.splitDays.indices, id: \.self) { i in
                            Button {
                                selectedDayIndex = i
                            } label: {
                                Text(String(store.splitDays[i].day.prefix(3)))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
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

                            // Workout name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Workout name")
                                    .font(.caption).foregroundStyle(.secondary)
                                TextField("e.g. Push A – Chest + Triceps", text: Binding(
                                    get: { day.workoutName },
                                    set: { day.workoutName = $0; store.saveSplitDay(day) }
                                ))
                                .textFieldStyle(.roundedBorder)
                            }

                            // Rest day toggle
                            Toggle("Rest day", isOn: Binding(
                                get: { day.isRestDay },
                                set: { day.isRestDay = $0; store.saveSplitDay(day) }
                            ))
                            .tint(.purple)

                            if !day.isRestDay {

                                // Copy plan button
                                if store.splitDays.filter({ !$0.isRestDay && !$0.exercises.isEmpty }).count > 0 {
                                    Button {
                                        showingCopyPlan = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "doc.on.doc")
                                            Text("Copy plan from another day")
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(.blue.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }

                                // Exercise list with drag to reorder
                                if !day.exercises.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
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
                                }

                                // Add exercise button
                                Button {
                                    showingAddExercise = true
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add exercise")
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.purple)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.purple.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
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
                CopyPlanSheet(
                    store: store,
                    currentDayIndex: selectedDayIndex
                ) { sourceDayIndex in
                    let source = store.splitDays[sourceDayIndex]
                    let target = store.splitDays[selectedDayIndex]
                    // Copy exercises from source to target
                    let copied = source.exercises.map {
                        SplitExercise(name: $0.name, targetSets: $0.targetSets, targetReps: $0.targetReps)
                    }
                    target.exercises.append(contentsOf: copied)
                    if target.workoutName.isEmpty {
                        target.workoutName = source.workoutName
                    }
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
                    // Skip current day and empty/rest days
                    if i != currentDayIndex && !day.isRestDay && !day.exercises.isEmpty {
                        Button {
                            onCopy(i)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(day.day)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text("\(day.exercises.count) exercises")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if !day.workoutName.isEmpty {
                                    Text(day.workoutName)
                                        .font(.caption)
                                        .foregroundStyle(.purple)
                                }
                                Text(day.exercises.prefix(3).map { $0.name }.joined(separator: ", ") + (day.exercises.count > 3 ? "..." : ""))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.red)
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
                    Text("Exercise name")
                        .font(.caption).foregroundStyle(.secondary)
                    TextField("e.g. Flat Barbell Press", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sets").font(.caption).foregroundStyle(.purple)
                        TextField("3", text: $sets)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Target reps").font(.caption).foregroundStyle(.blue)
                        TextField("8-12", text: $reps)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                Button {
                    onAdd(SplitExercise(
                        name: name,
                        targetSets: Int(sets) ?? 3,
                        targetReps: reps
                    ))
                } label: {
                    Text("Add")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
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
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.red)
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
                        Text("Workout name")
                            .font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. Push A – Chest + Triceps", text: $workoutName)
                            .textFieldStyle(.roundedBorder)
                    }
                    .onAppear { workoutName = dayPlan?.workoutName ?? "" }

                    if let exercises = dayPlan?.exercises, !exercises.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Exercises from split")
                                .font(.caption).foregroundStyle(.secondary)
                            ForEach(exercises) { ex in
                                HStack {
                                    Text(ex.name).font(.subheadline)
                                    Spacer()
                                    Text("\(ex.targetSets)×\(ex.targetReps)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.gray.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
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
                        Text("Start Workout")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
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
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

// MARK: - Active Workout

struct ActiveWorkoutView: View {
    let store: WorkoutStore
    @Binding var isPresented: Bool
    @State private var showingAddExercise = false
    @State private var showingFinishConfirm = false
    @State private var showingCancelConfirm = false
    @State private var elapsedSeconds = 0
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

                        // Timer row
                        HStack {
                            VStack(spacing: 2) {
                                Text(formatTime(elapsedSeconds))
                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.purple)
                                Text("elapsed")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if restTimerRunning {
                                VStack(spacing: 2) {
                                    Text(formatTime(restTimerSeconds))
                                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                                        .foregroundStyle(restTimerSeconds <= 10 ? .red : .orange)
                                    Text("rest")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Button {
                                    restTimerRunning = false
                                    restTimerSeconds = 0
                                } label: {
                                    Text("Skip")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Menu {
                                    ForEach(restOptions, id: \.self) { sec in
                                        Button("\(sec)s rest") {
                                            selectedRestTime = sec
                                            startRestTimer()
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "timer")
                                        Text("Rest timer")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.orange.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding()
                        .background(.gray.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .id("top")

                        // Exercise cards
                        if let session = store.activeSession {
                            ForEach(session.exercises.indices, id: \.self) { exIndex in
                                ExerciseLogCard(
                                    store: store,
                                    exerciseIndex: exIndex,
                                    onSetCompleted: {
                                        startRestTimer()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                proxy.scrollTo("input_\(exIndex)", anchor: .bottom)
                                            }
                                        }
                                    },
                                    onFocused: {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                proxy.scrollTo("input_\(exIndex)", anchor: .bottom)
                                            }
                                        }
                                    }
                                )
                                .id("exercise_\(exIndex)")
                            }
                        }

                        // Add exercise
                        Button {
                            showingAddExercise = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add exercise")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.purple.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Finish button
                        Button {
                            showingFinishConfirm = true
                        } label: {
                            Text("Finish Workout")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.purple)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Color.clear.frame(height: 350)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(store.activeSession?.name ?? "Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCancelConfirm = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .onReceive(timer) { _ in
                elapsedSeconds += 1
                if restTimerRunning {
                    if restTimerSeconds > 0 {
                        restTimerSeconds -= 1
                    } else {
                        restTimerRunning = false
                    }
                }
            }
            .alert("Finish Workout?", isPresented: $showingFinishConfirm) {
                Button("Finish", role: .destructive) {
                    store.finishSession()
                    isPresented = false
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will save your session and update personal bests.")
            }
            .alert("Cancel Workout?", isPresented: $showingCancelConfirm) {
                Button("Discard", role: .destructive) {
                    store.cancelSession()
                    isPresented = false
                }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text("Your workout progress will be lost.")
            }
            .sheet(isPresented: $showingAddExercise) {
                AddSplitExerciseSheet { ex in
                    let active = ActiveExercise(
                        name: ex.name,
                        targetSets: ex.targetSets,
                        targetReps: ex.targetReps
                    )
                    store.activeSession?.exercises.append(active)
                    showingAddExercise = false
                }
            }
        }
    }

    func startRestTimer() {
        restTimerSeconds = selectedRestTime
        restTimerRunning = true
    }

    func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
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

    var exercise: ActiveExercise? {
        store.activeSession?.exercises[exerciseIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(exercise?.name ?? "")
                        .font(.headline)
                    Spacer()
                    if let pb = store.pb(for: exercise?.name ?? "") {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                            Text("PB: \(pb.display)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Text("Target: \(exercise?.targetSets ?? 0) sets × \(exercise?.targetReps ?? "") reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let lastSets = store.lastSets(for: exercise?.name ?? "")
                if !lastSets.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            Text("Last:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            ForEach(lastSets.filter { !$0.isWarmup }) { set in
                                Text("\(String(format: "%g", set.weight))kg×\(set.reps)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Logged sets table
            if let sets = exercise?.sets, !sets.isEmpty {
                Divider().padding(.horizontal, 16)

                HStack {
                    Text("Set").font(.caption).foregroundStyle(.secondary).frame(width: 30)
                    Text("Weight").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    Text("Reps").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    Text("Type").font(.caption).foregroundStyle(.secondary).frame(width: 64)
                    Spacer().frame(width: 24)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)

                ForEach(sets.indices, id: \.self) { i in
                    let set = sets[i]
                    HStack {
                        Text("\(i + 1)")
                            .font(.caption).foregroundStyle(.secondary).frame(width: 30)
                        Text("\(String(format: "%g", set.weight))kg")
                            .font(.subheadline).fontWeight(.medium).frame(maxWidth: .infinity)
                        Text("\(set.reps)")
                            .font(.subheadline).fontWeight(.medium).frame(maxWidth: .infinity)
                        Text(set.isWarmup ? "Warmup" : "Working")
                            .font(.caption2)
                            .foregroundStyle(set.isWarmup ? .orange : .purple)
                            .frame(width: 64)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .frame(width: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(set.isWarmup ? Color.orange.opacity(0.04) : Color.green.opacity(0.04))
                    Divider().padding(.horizontal, 16)
                }
            }

            // Input section
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weight (kg)")
                            .font(.caption2).foregroundStyle(.secondary)
                        TextField("0", text: $weightInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .focused($weightFocused)
                            .onChange(of: weightFocused) { _, focused in
                                if focused { onFocused() }
                            }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reps")
                            .font(.caption2).foregroundStyle(.secondary)
                        TextField("0", text: $repsInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .focused($repsFocused)
                            .onChange(of: repsFocused) { _, focused in
                                if focused { onFocused() }
                            }
                    }
                }

                HStack {
                    Toggle("Warmup", isOn: $isWarmup)
                        .font(.caption)
                        .tint(.orange)
                    Spacer()
                    Button {
                        addSet()
                    } label: {
                        Text("+ Log Set")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
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
        guard let weight = Double(weightInput),
              let reps = Int(repsInput),
              let session = store.activeSession else { return }

        let newSet = LoggedSet(weight: weight, reps: reps, isWarmup: isWarmup, completed: true)
        session.exercises[exerciseIndex].sets.append(newSet)

        weightInput = ""
        repsInput = ""

        if !isWarmup { onSetCompleted() }
        isWarmup = false
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    let session: WorkoutSession
    let store: WorkoutStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    HStack(spacing: 0) {
                        StatBox(value: store.formatDuration(session.durationSeconds), label: "Duration")
                        Divider().frame(height: 40)
                        StatBox(value: "\(session.exercises.count)", label: "Exercises")
                        Divider().frame(height: 40)
                        StatBox(
                            value: "\(session.exercises.reduce(0) { $0 + $1.sets.count })",
                            label: "Total sets"
                        )
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
                                        HStack(spacing: 4) {
                                            Image(systemName: "trophy.fill")
                                                .font(.caption2).foregroundStyle(.yellow)
                                            Text("New PB!")
                                                .font(.caption).foregroundStyle(.yellow)
                                        }
                                    }
                                }
                                HStack(spacing: 12) {
                                    let workingSets = exercise.sets.filter { !$0.isWarmup }
                                    let warmupSets = exercise.sets.filter { $0.isWarmup }
                                    Text("\(workingSets.count) working sets")
                                        .font(.caption).foregroundStyle(.secondary)
                                    if !warmupSets.isEmpty {
                                        Text("\(warmupSets.count) warmup")
                                            .font(.caption).foregroundStyle(.orange.opacity(0.8))
                                    }
                                    Text("Vol: \(Int(exercise.totalVolume))kg")
                                        .font(.caption).foregroundStyle(.purple)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                            if !exercise.sets.isEmpty {
                                Divider().padding(.horizontal, 16)
                                HStack {
                                    Text("Set").font(.caption).foregroundStyle(.secondary).frame(width: 30)
                                    Text("Weight").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                                    Text("Reps").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                                    Text("Volume").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                                    Text("Type").font(.caption).foregroundStyle(.secondary).frame(width: 60)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)

                                ForEach(exercise.sets.indices, id: \.self) { i in
                                    let set = exercise.sets[i]
                                    let volume = set.weight * Double(set.reps)
                                    let isBest = !set.isWarmup && exercise.bestSet?.id == set.id

                                    HStack {
                                        Text("\(i + 1)")
                                            .font(.caption).foregroundStyle(.secondary).frame(width: 30)
                                        Text("\(String(format: "%g", set.weight))kg")
                                            .font(.subheadline).fontWeight(.medium).frame(maxWidth: .infinity)
                                        Text("\(set.reps)")
                                            .font(.subheadline).fontWeight(.medium).frame(maxWidth: .infinity)
                                        HStack(spacing: 2) {
                                            Text("\(Int(volume))kg")
                                                .font(.subheadline)
                                                .fontWeight(isBest ? .semibold : .regular)
                                                .foregroundStyle(isBest ? .purple : .primary)
                                            if isBest {
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundStyle(.purple)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        Text(set.isWarmup ? "Warmup" : "Working")
                                            .font(.caption2)
                                            .foregroundStyle(set.isWarmup ? .orange : .purple)
                                            .frame(width: 60)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        set.isWarmup ? Color.orange.opacity(0.04) :
                                        isBest ? Color.purple.opacity(0.06) : Color.clear
                                    )
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.purple)
                }
            }
        }
    }

    var totalVolumeDisplay: String {
        let vol = session.exercises.reduce(0.0) { $0 + $1.totalVolume }
        return vol >= 1000 ? String(format: "%.1ft", vol / 1000) : "\(Int(vol))kg"
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
