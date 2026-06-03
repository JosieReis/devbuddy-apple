import SwiftUI
import Combine

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case error(String)

    var label: String {
        switch self {
        case .disconnected: return "Desconectado"
        case .connecting: return "Conectando..."
        case .connected: return "Conectado"
        case .error(let msg): return "Erro: \(msg)"
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

    private var apiClient: APIClient?
    private var poller: EventPoller?

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
            connectionStatus = .error("Falha na conexão")
        }
    }

    func restoreSession() async {
        guard let token = KeychainService.load() else { return }
        await connect(with: token)
    }

    func disconnect() {
        poller?.stopPolling()
        poller = nil
        apiClient = nil
        try? KeychainService.delete()
        connectionStatus = .disconnected
        nextEvent = nil
        minutesUntilNext = nil
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
    }
}
