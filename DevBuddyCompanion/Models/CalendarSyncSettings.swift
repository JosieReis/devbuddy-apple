import Foundation

struct CalendarSyncSettings {
    var enabledCalendarIDs: Set<String>
    var calendarAliases: [String: String]
    var daysAhead: Int
    var intervalMinutes: Int

    init() {
        let savedIDs = UserDefaults.standard.stringArray(forKey: "calendarSync.enabledIDs") ?? []
        self.enabledCalendarIDs = Set(savedIDs)
        self.calendarAliases = UserDefaults.standard.dictionary(forKey: "calendarSync.aliases") as? [String: String] ?? [:]
        self.daysAhead = UserDefaults.standard.object(forKey: "calendarSync.daysAhead") as? Int ?? 30
        self.intervalMinutes = UserDefaults.standard.object(forKey: "calendarSync.intervalMinutes") as? Int ?? 15
    }

    func save() {
        UserDefaults.standard.set(Array(enabledCalendarIDs), forKey: "calendarSync.enabledIDs")
        UserDefaults.standard.set(calendarAliases, forKey: "calendarSync.aliases")
        UserDefaults.standard.set(daysAhead, forKey: "calendarSync.daysAhead")
        UserDefaults.standard.set(intervalMinutes, forKey: "calendarSync.intervalMinutes")
    }
}
