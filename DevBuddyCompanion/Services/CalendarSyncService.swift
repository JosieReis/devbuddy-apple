import EventKit
import Foundation

struct CalendarSyncConfig {
    var enabledCalendarIDs: Set<String>
    var calendarAliases: [String: String]
    var daysAhead: Int
    var importSecret: String
}

struct ImportResult {
    let synced: Int
    let feeds: Int
}

@MainActor
final class CalendarSyncService {
    private let store = EKEventStore()
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(macOS 14.0, *) {
                store.requestFullAccessToEvents { granted, _ in
                    continuation.resume(returning: granted)
                }
            } else {
                store.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func discoverCalendars() -> [EKCalendar] {
        let skipTitles = ["birthdays", "aniversários", "holidays", "feriados"]
        return store.calendars(for: .event).filter { cal in
            if cal.type == .birthday { return false }
            let lower = cal.title.lowercased()
            return !skipTitles.contains(where: { lower.contains($0) })
        }
    }

    func sync(
        config: CalendarSyncConfig,
        userId: String,
        source: String = "companion-mac"
    ) async throws -> ImportResult {
        let calendars = store.calendars(for: .event).filter {
            config.enabledCalendarIDs.contains($0.calendarIdentifier)
        }
        guard !calendars.isEmpty else { return ImportResult(synced: 0, feeds: 0) }

        let startDate = Calendar.current.startOfDay(for: Date())
        guard let endDate = Calendar.current.date(
            byAdding: .day,
            value: config.daysAhead,
            to: startDate
        ) else {
            return ImportResult(synced: 0, feeds: 0)
        }

        let predicate = store.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )
        let events = store.events(matching: predicate)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")

        var feedNames = Set<String>()
        var eventDicts: [[String: Any]] = []

        for event in events {
            let calID = event.calendar.calendarIdentifier
            let feedName = config.calendarAliases[calID] ?? event.calendar.title
            feedNames.insert(feedName)

            let title = "[\(feedName)] \(event.title ?? "(no title)")"

            // Unique ID: eventIdentifier + startDate for recurring events
            let baseId = event.eventIdentifier ?? UUID().uuidString
            let dateSuffix = event.startDate != nil
                ? "_\(dateFormatter.string(from: event.startDate!))"
                : ""
            let uniqueId = baseId.contains("/RID=")
                ? baseId
                : "\(baseId)\(dateSuffix)"

            var dict: [String: Any] = [
                "externalId": uniqueId,
                "title": title,
                "allDay": event.isAllDay,
                "calendar": feedName,
            ]

            if let start = event.startDate {
                dict["startAt"] = isoFormatter.string(from: start)
            }
            if let end = event.endDate {
                dict["endAt"] = isoFormatter.string(from: end)
            }
            if let loc = event.location, !loc.isEmpty {
                dict["location"] = loc
            }
            if let notes = event.notes, !notes.isEmpty {
                dict["notes"] = String(notes.prefix(500))
            }

            // Build recurrence rule
            if let rules = event.recurrenceRules, let rule = rules.first {
                var parts: [String] = []
                switch rule.frequency {
                case .daily: parts.append("FREQ=DAILY")
                case .weekly: parts.append("FREQ=WEEKLY")
                case .monthly: parts.append("FREQ=MONTHLY")
                case .yearly: parts.append("FREQ=YEARLY")
                @unknown default: break
                }
                if rule.interval > 1 {
                    parts.append("INTERVAL=\(rule.interval)")
                }
                if let days = rule.daysOfTheWeek {
                    let dayMap: [EKWeekday: String] = [
                        .monday: "MO", .tuesday: "TU", .wednesday: "WE",
                        .thursday: "TH", .friday: "FR", .saturday: "SA",
                        .sunday: "SU",
                    ]
                    let dayStrs = days.compactMap { dayMap[$0.dayOfTheWeek] }
                    if !dayStrs.isEmpty {
                        parts.append("BYDAY=\(dayStrs.joined(separator: ","))")
                    }
                }
                if let end = rule.recurrenceEnd {
                    if let endDate = end.endDate {
                        let df = DateFormatter()
                        df.dateFormat = "yyyyMMdd"
                        df.timeZone = TimeZone(identifier: "UTC")
                        parts.append("UNTIL=\(df.string(from: endDate))")
                    } else if end.occurrenceCount > 0 {
                        parts.append("COUNT=\(end.occurrenceCount)")
                    }
                }
                if !parts.isEmpty {
                    dict["recurrenceRule"] = parts.joined(separator: ";")
                }
            }

            eventDicts.append(dict)
        }

        // POST to /calendar/import
        try await apiClient.importEvents(
            userId: userId,
            source: source,
            events: eventDicts,
            importSecret: config.importSecret
        )

        return ImportResult(synced: eventDicts.count, feeds: feedNames.count)
    }
}
