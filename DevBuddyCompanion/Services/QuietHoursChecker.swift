import Foundation

struct QuietHoursChecker {
    /// Check if current time is within quiet hours.
    /// quietHoursStart/End are "HH:mm" strings (e.g., "22:30", "07:00").
    /// Handles overnight ranges (e.g., 22:30 → 07:00).
    func isInQuietHours(preferences: NotificationPreferences) -> Bool {
        guard let startStr = preferences.quietHoursStart,
              let endStr = preferences.quietHoursEnd else {
            return false
        }

        guard let startMinutes = parseTimeToMinutes(startStr),
              let endMinutes = parseTimeToMinutes(endStr) else {
            return false
        }

        let now = Date()
        let calendar = Calendar.current
        let currentMinutes = calendar.component(.hour, from: now) * 60
            + calendar.component(.minute, from: now)

        if startMinutes <= endMinutes {
            // Same-day range (e.g., 09:00 → 17:00)
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        } else {
            // Overnight range (e.g., 22:00 → 07:00)
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        }
    }

    private func parseTimeToMinutes(_ time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              let hours = Int(parts[0]),
              let minutes = Int(parts[1]) else {
            return nil
        }
        return hours * 60 + minutes
    }
}
