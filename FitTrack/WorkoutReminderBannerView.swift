import SwiftUI
import UserNotifications

/// Drop this view anywhere inside DashboardView's ScrollView.
/// It owns no state itself — everything flows through NotificationManager.shared.
struct WorkoutReminderBannerView: View {

    @ObservedObject private var nm = NotificationManager.shared

    /// Workout weekdays derived from WorkoutStore's split (1=Sun … 7=Sat).
    let workoutWeekdays: Set<Int>

    @State private var showPermissionAlert = false
    @State private var isExpanded          = false

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            headerRow
            if isExpanded {
                expandedContent
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
        .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enable notifications in Settings so FitTrack can remind you about missed workouts.")
        }
    }

    // MARK: - Header
    private var headerRow: some View {
        Button {
            withAnimation { isExpanded.toggle() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge")
                    .font(.title3)
                    .foregroundStyle(nm.isEnabled ? .orange : .secondary)
                    .symbolEffect(.bounce, value: nm.isEnabled)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Workout Reminder")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(nm.isEnabled
                         ? "Reminds you at \(formattedTime) on workout days"
                         : "Tap to set up a missed-workout alert")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: toggleBinding)
                    .labelsHidden()
                    .tint(.orange)

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded content
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider().padding(.horizontal, 16)

            HStack {
                Label("Remind me at", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker(
                    "",
                    selection: $nm.reminderDate,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .onChange(of: nm.reminderDate) { _, _ in
                    Task { await nm.reschedule(workoutWeekdays: workoutWeekdays) }
                }
            }
            .padding(.horizontal, 16)

            if !workoutWeekdays.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Active on your workout days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    HStack(spacing: 6) {
                        ForEach(1...7, id: \.self) { wd in
                            let active = workoutWeekdays.contains(wd)
                            Text(shortWeekday(wd))
                                .font(.caption2.weight(.semibold))
                                .frame(width: 32, height: 24)
                                .background(active ? Color.orange : Color(.tertiarySystemFill),
                                            in: RoundedRectangle(cornerRadius: 6))
                                .foregroundStyle(active ? .white : .secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                Label("Add workout days in Workout → Edit Split first.",
                      systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
            }

            Spacer(minLength: 14)
        }
    }

    // MARK: - Helpers
    private var formattedTime: String {
        nm.reminderDate.formatted(date: .omitted, time: .shortened)
    }

    private func shortWeekday(_ weekday: Int) -> String {
        ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"][weekday - 1]
    }

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { nm.isEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        let granted = await nm.requestAuthorization()
                        if granted {
                            nm.isEnabled = true
                            await nm.reschedule(workoutWeekdays: workoutWeekdays)
                        } else {
                            showPermissionAlert = true
                        }
                    }
                } else {
                    nm.isEnabled = false
                    nm.cancelAll()
                }
            }
        )
    }
}
