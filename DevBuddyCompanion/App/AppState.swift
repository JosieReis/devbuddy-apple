import SwiftUI
import Combine

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case error(String)

    var label: String {
        switch self {
        case .disconnected: return String(localized: "status.disconnected")
        case .connecting: return String(localized: "status.connecting")
        case .connected: return String(localized: "status.connected")
        case .error(let msg): return String(localized: "status.error \(msg)")
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var nextEvent: CalendarEvent?
    @Published var minutesUntilNext: Int?
    @Published var reminderMinutes: Int = 10
    @Published var lastSyncDate: Date?
    @Published var syncedCalendarCount: Int = 0

    private var apiClient: APIClient?
    private var poller: EventPoller?
    private(set) var calendarSyncService: CalendarSyncService?
    private var syncTimer: Timer?

    var menuBarIcon: String {
        if nextEvent != nil {
            return "airplane.circle.fill"
        }
        return connectionStatus.isConnected ? "airplane" : "airplane.circle"
    }

    var hasToken: Bool {
        KeychainService.load() != nil
    }

    func connect(with token: String) async {
        connectionStatus = .connecting

        let client = APIClient(
            baseURL: APIEndpoint.baseURL,
            token: token
        )

        do {
            // Validate token by fetching events
            let _: [CalendarEvent] = try await client.request(.upcomingEvents(minutesAhead: 10))
            try KeychainService.save(token: token)
            self.apiClient = client
            connectionStatus = .connected
            startPolling()
        } catch let error as APIError {
            connectionStatus = .error(error.userMessage)
        } catch {
            connectionStatus = .error(String(localized: "status.connectionFailed"))
        }
    }

    func restoreSession() async {
        guard let token = KeychainService.load() else { return }
        await connect(with: token)
    }

    func disconnect() {
        poller?.stopPolling()
        poller = nil
        syncTimer?.invalidate()
        syncTimer = nil
        calendarSyncService = nil
        apiClient = nil
        try? KeychainService.delete()
        try? KeychainService.deleteImportSecret()
        connectionStatus = .disconnected
        nextEvent = nil
        minutesUntilNext = nil
        lastSyncDate = nil
        syncedCalendarCount = 0
    }

    func updateReminderMinutes(_ minutes: Int) async {
        reminderMinutes = minutes
        guard let client = apiClient else { return }

        do {
            try await client.updatePreferences(calendarReminderMinutes: minutes)
        } catch {
            // Keep local value even if sync fails
        }
    }

    private func startPolling() {
        guard let client = apiClient else { return }

        let poller = EventPoller(apiClient: client, appState: self)
        self.poller = poller
        poller.startPolling()

        // Initialize calendar sync service
        calendarSyncService = CalendarSyncService(apiClient: client)
    }

    func startCalendarSync() {
        let settings = CalendarSyncSettings()
        let interval = TimeInterval(settings.intervalMinutes * 60)

        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.syncNow()
            }
        }

        // Also sync immediately
        Task { await syncNow() }
    }

    func syncNow() async {
        guard let syncService = calendarSyncService else { return }
        guard let importSecret = KeychainService.loadImportSecret(),
              !importSecret.isEmpty
        else { return }

        let settings = CalendarSyncSettings()
        guard !settings.enabledCalendarIDs.isEmpty else { return }

        let config = CalendarSyncConfig(
            enabledCalendarIDs: settings.enabledCalendarIDs,
            calendarAliases: settings.calendarAliases,
            daysAhead: settings.daysAhead,
            importSecret: importSecret
        )

        // Use "me" as userId — the API resolves from the token
        do {
            let result = try await syncService.sync(
                config: config,
                userId: "me"
            )
            lastSyncDate = Date()
            syncedCalendarCount = result.feeds
            print("[CalendarSync] Synced \(result.synced) events from \(result.feeds) calendars")
        } catch {
            print("[CalendarSync] Sync failed: \(error)")
        }
    }
}
