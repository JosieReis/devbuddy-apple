import Foundation

struct CalendarEvent: Codable, Identifiable {
    let id: String
    let title: String
    let startAt: Date?
    let endAt: Date?
    let startDate: String?
    let endDate: String?
    let location: String?
    let conferenceUrl: String?
    let status: String
    let allDay: Bool

    var isUpcoming: Bool {
        guard !allDay, status != "cancelled", let startAt else {
            return false
        }
        return startAt > Date()
    }

    func minutesUntilStart() -> Int? {
        guard let startAt else { return nil }
        let interval = startAt.timeIntervalSince(Date())
        guard interval > 0 else { return nil }
        return Int(ceil(interval / 60))
    }
}
