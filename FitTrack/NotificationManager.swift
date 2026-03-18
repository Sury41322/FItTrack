import UserNotifications
import SwiftUI
import Combine

/// Manages scheduling and cancellation of the "missed workout" local notification.
final class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    // MARK: - UserDefaults keys
    private let enabledKey  = "missedWorkout.enabled"
    private let hourKey     = "missedWorkout.hour"
    private let minuteKey   = "missedWorkout.minute"

    // MARK: - Notification identifiers
    /// One identifier per weekday (1 = Sunday … 7 = Saturday) so we can
    /// surgically cancel only rest-day slots when the split changes.
    private func identifier(for weekday: Int) -> String {
        "missedWorkout.weekday.\(weekday)"
    }

    // MARK: - Published state (drives Dashboard UI)
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: enabledKey) }
    }
    @Published var reminderDate: Date {
        didSet {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
            UserDefaults.standard.set(comps.hour ?? 21,   forKey: hourKey)
            UserDefaults.standard.set(comps.minute ?? 0,  forKey: minuteKey)
        }
    }

    // MARK: - Init
    private init() {
        let enabled = UserDefaults.standard.bool(forKey: "missedWorkout.enabled")
        let hour    = UserDefaults.standard.object(forKey: "missedWorkout.hour")   as? Int ?? 21
        let minute  = UserDefaults.standard.object(forKey: "missedWorkout.minute") as? Int ?? 0

        self.isEnabled = enabled

        var comps        = DateComponents()
        comps.hour       = hour
        comps.minute     = minute
        self.reminderDate = Calendar.current.date(from: comps) ?? Date()
    }

    // MARK: - Permission
    func requestAuthorization() async -> Bool {
        do {
            let center  = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Schedule / Cancel
    /// Call this whenever: toggle flipped, time changed, or split updated.
    /// `workoutWeekdays` — set of weekday integers (1=Sun…7=Sat) that are
    /// workout days according to the user's split.
    func reschedule(workoutWeekdays: Set<Int>) async {
        let center = UNUserNotificationCenter.current()

        // Always wipe existing missed-workout notifications first.
        let allIds = (1...7).map { identifier(for: $0) }
        center.removePendingNotificationRequests(withIdentifiers: allIds)

        guard isEnabled, !workoutWeekdays.isEmpty else { return }

        let status = await authorizationStatus()
        guard status == .authorized else { return }

        let comps  = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
        let hour   = comps.hour   ?? 21
        let minute = comps.minute ?? 0

        for weekday in workoutWeekdays {
            var trigger        = DateComponents()
            trigger.weekday    = weekday
            trigger.hour       = hour
            trigger.minute     = minute

            let content        = UNMutableNotificationContent()
            content.title      = "Workout Reminder 💪"
            content.body       = "You haven't logged today's workout yet. Finish strong!"
            content.sound      = .default

            let request = UNNotificationRequest(
                identifier: identifier(for: weekday),
                content:    content,
                trigger:    UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
            )

            do {
                try await center.add(request)
            } catch {
                print("NotificationManager: failed to schedule weekday \(weekday): \(error)")
            }
        }
    }

    func cancelAll() {
        let allIds = (1...7).map { identifier(for: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allIds)
    }

    // MARK: - Rest Timer Notification

    private let restTimerID = "restTimer.finished"

    /// Schedules a one-shot notification to fire after `seconds`.
    /// Safe to call even if notifications aren't authorised — no-ops silently.
    func scheduleRestTimer(seconds: Int) {
        cancelRestTimer()

        let content   = UNMutableNotificationContent()
        content.title = "Rest finished ✅"
        content.body  = "Rest finished — next set!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(seconds, 1)),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: restTimerID,
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("RestTimer notification error: \(error)") }
        }
    }

    /// Cancels any pending rest timer notification (e.g. user tapped Skip).
    func cancelRestTimer() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [restTimerID])
    }
}
