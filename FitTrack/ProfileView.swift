//
//  ProfileView.swift
//  FitTrack
//
//  Created by Surya Sushad on 16/03/26.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(ProfileStore.self) var profileStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var age = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var calorieGoal = ""
    @State private var stepGoal = ""
    @State private var showingSaved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Avatar header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(.purple.opacity(0.15))
                                .frame(width: 80, height: 80)
                            if name.isEmpty {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.purple)
                            } else {
                                Text(initials)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.purple)
                            }
                        }
                        if !name.isEmpty {
                            Text(name)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Personal info
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Personal Info")
                            .font(.headline)
                            .padding(.horizontal, 4)

                        ProfileField(icon: "person.fill", label: "Name", placeholder: "Your name", text: $name, keyboardType: .default)
                        ProfileField(icon: "calendar", label: "Age", placeholder: "25", text: $age, keyboardType: .numberPad)
                        ProfileField(icon: "ruler.fill", label: "Height (cm)", placeholder: "170", text: $height, keyboardType: .decimalPad)
                        ProfileField(icon: "scalemass.fill", label: "Weight (kg)", placeholder: "70", text: $weight, keyboardType: .decimalPad)
                    }

                    // Goals
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Daily Goals")
                            .font(.headline)
                            .padding(.horizontal, 4)

                        ProfileField(icon: "flame.fill", label: "Calorie Goal (kcal)", placeholder: "2000", text: $calorieGoal, keyboardType: .numberPad, color: .orange)
                        ProfileField(icon: "figure.walk", label: "Step Goal", placeholder: "10000", text: $stepGoal, keyboardType: .numberPad, color: .purple)
                    }

                    // Save button
                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            if showingSaved {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Saved!")
                            } else {
                                Text("Save Changes")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
            }
            .navigationTitle("Profile & Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.purple)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear { loadProfile() }
        }
    }

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return name.prefix(2).uppercased()
    }

    func loadProfile() {
        let p = profileStore.profile
        name = p.name
        age = p.age > 0 ? "\(p.age)" : ""
        height = p.heightCm > 0 ? String(format: "%g", p.heightCm) : ""
        weight = p.weightKg > 0 ? String(format: "%g", p.weightKg) : ""
        calorieGoal = "\(p.calorieGoal)"
        stepGoal = "\(p.stepGoal)"
    }

    func saveProfile() {
        // Dismiss keyboard first so UI feels snappy
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
        let p = profileStore.profile
        p.name        = name
        p.age         = Int(age)         ?? p.age
        p.heightCm    = Double(height)   ?? p.heightCm
        p.weightKg    = Double(weight)   ?? p.weightKg
        p.calorieGoal = Int(calorieGoal) ?? p.calorieGoal
        p.stepGoal    = Int(stepGoal)    ?? p.stepGoal
        // Defer SwiftData write so keyboard dismiss animation completes first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            profileStore.save()
        }
        withAnimation { showingSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showingSaved = false }
        }
    }
}

// MARK: - Profile Field

struct ProfileField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var color: Color = .blue

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, configurations: config)
    ProfileView()
        .modelContainer(container)
        .environment(ProfileStore(modelContext: container.mainContext))
}
