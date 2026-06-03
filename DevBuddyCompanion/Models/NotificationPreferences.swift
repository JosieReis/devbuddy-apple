import Foundation

struct NotificationPreferences: Codable {
    let calendarReminderEnabled: Bool
    let calendarReminderMinutes: Int
    let quietHoursStart: String?
    let quietHoursEnd: String?
    let maxPerHour: Int
}

struct UpdatePreferencesBody: Encodable {
    let calendarReminderMinutes: Int?
}
