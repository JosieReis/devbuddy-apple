import Foundation

@MainActor
final class EventPoller {
    private let apiClient: APIClient
    private weak var appState: AppState?
    private var pollingTask: Task<Void, Never>?
    private var shownEventIDs: Set<String> = []
    private var animationsThisHour: Int = 0
    private var currentHour: Int = Calendar.current.component(.hour, from: Date())

    private let quietHoursChecker = QuietHoursChecker()

    init(apiClient: APIClient, appState: AppState) {
        self.apiClient = apiClient
        self.appState = appState
        loadShownEvents()
    }

    func startPolling() {
        pollingTask = Task { [weak self] in
            // Initial poll immediately
            await self?.poll()

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await self?.poll()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func poll() async {
        guard let appState else { return }

        do {
            // Fetch preferences for quiet hours and reminder config
            let preferences: NotificationPreferences = try await apiClient.request(.preferences)

            guard preferences.calendarReminderEnabled else {
                appState.nextEvent = nil
                appState.minutesUntilNext = nil
                return
            }

            // Fetch upcoming events
            let events: [CalendarEvent] = try await apiClient.request(
                .upcomingEvents(minutesAhead: preferences.calendarReminderMinutes)
            )

            // Filter to valid upcoming timed events
            let upcoming = events
                .filter { $0.isUpcoming }
                .sorted { ($0.startAt ?? .distantFuture) < ($1.startAt ?? .distantFuture) }

            let nextEvent = upcoming.first
            appState.nextEvent = nextEvent
            appState.minutesUntilNext = nextEvent?.minutesUntilStart()
            appState.reminderMinutes = preferences.calendarReminderMinutes

            // Check if we should trigger animation
            guard let event = nextEvent else {
                print("[Poller] No upcoming event")
                return
            }
            guard !shownEventIDs.contains(event.id) else {
                print("[Poller] Event \(event.id) already shown")
                return
            }
            guard !quietHoursChecker.isInQuietHours(preferences: preferences) else {
                print("[Poller] In quiet hours, skipping")
                return
            }
            guard canAnimateThisHour(maxPerHour: preferences.maxPerHour) else {
                print("[Poller] Rate limit reached")
                return
            }

            print("[Poller] Will trigger animation for: \(event.title)")
            // Trigger animation
            shownEventIDs.insert(event.id)
            saveShownEvents()
            trackAnimation()

            if let minutes = event.minutesUntilStart() {
                AirplaneAnimationController.shared.triggerAnimation(
                    message: "Reunião em \(minutes) min",
                    title: event.title
                )
            }
        } catch {
            // On auth error, disconnect
            if let apiError = error as? APIError, case .unauthorized = apiError {
                appState.disconnect()
            }
            // Other errors: silently retry next cycle
        }
    }

    // MARK: - Rate Limiting

    private func canAnimateThisHour(maxPerHour: Int) -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour != currentHour {
            currentHour = hour
            animationsThisHour = 0
        }
        return animationsThisHour < maxPerHour
    }

    private func trackAnimation() {
        animationsThisHour += 1
    }

    // MARK: - Dedup Persistence

    private let shownEventsKey = "shownEventIDs"
    private let shownEventsDateKey = "shownEventIDsDate"

    private func loadShownEvents() {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = UserDefaults.standard.object(forKey: shownEventsDateKey) as? Date

        // Clear if saved from a different day
        if let savedDate, !Calendar.current.isDate(savedDate, inSameDayAs: today) {
            UserDefaults.standard.removeObject(forKey: shownEventsKey)
            UserDefaults.standard.set(today, forKey: shownEventsDateKey)
            return
        }

        if let saved = UserDefaults.standard.stringArray(forKey: shownEventsKey) {
            shownEventIDs = Set(saved)
        }
        UserDefaults.standard.set(today, forKey: shownEventsDateKey)
    }

    private func saveShownEvents() {
        UserDefaults.standard.set(Array(shownEventIDs), forKey: shownEventsKey)
    }
}
