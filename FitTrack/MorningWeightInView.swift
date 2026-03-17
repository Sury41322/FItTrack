//
//  MorningWeighInView.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI

struct MorningWeighInView: View {
    @Environment(WeightStore.self) var weightStore
    @Environment(ProfileStore.self) var profileStore
    @Environment(\.dismiss) var dismiss

    @State private var weightText = ""
    @State private var selectedMood: Mood = .good
    @State private var showError = false

    var greeting: String {
        let name = profileStore.name
        return name.isEmpty ? "Good morning!" : "Good morning, \(name)!"
    }

    var lastWeightHint: String {
        if let last = weightStore.latestEntry {
            return String(format: "Last logged: %g kg", last.weightKg)
        }
        return String(format: "Profile weight: %g kg", profileStore.profile.weightKg)
    }

    var body: some View {
        VStack(spacing: 0) {

            // Header
            VStack(spacing: 6) {
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Let's log your morning weight")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .background(.purple.opacity(0.07))

            ScrollView {
                VStack(spacing: 28) {

                    // Weight input
                    VStack(spacing: 12) {
                        Text("Today's Weight")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            TextField("0.0", text: $weightText)
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.purple)

                            Text("kg")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 8)
                        }
                        .padding()
                        .background(.gray.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        Text(lastWeightHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if showError {
                            Text("Please enter a valid weight")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    // Mood picker
                    VStack(spacing: 12) {
                        Text("How are you feeling?")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 10) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                MoodButton(
                                    mood: mood,
                                    isSelected: selectedMood == mood
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedMood = mood
                                    }
                                }
                            }
                        }
                    }

                    // Log button
                    Button {
                        logWeight()
                    } label: {
                        Text("Log Weight")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Skip
                    Button {
                        dismiss()
                    } label: {
                        Text("Skip for today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
        }
        .onAppear {
            // Pre-fill with last logged weight for convenience
            if let last = weightStore.latestEntry {
                weightText = String(format: "%g", last.weightKg)
            } else if profileStore.profile.weightKg > 0 {
                weightText = String(format: "%g", profileStore.profile.weightKg)
            }
        }
    }

    func logWeight() {
        guard let kg = Double(weightText), kg > 20, kg < 300 else {
            showError = true
            return
        }
        weightStore.log(weightKg: kg, mood: selectedMood)
        dismiss()
    }
}

// MARK: - Mood Button

struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: 28))
                Text(mood.label)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .purple : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? .purple.opacity(0.12) : .gray.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
