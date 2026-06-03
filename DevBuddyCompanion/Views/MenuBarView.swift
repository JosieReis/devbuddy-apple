import SwiftUI
import ServiceManagement

struct MenuBarView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        if appState.hasToken && appState.connectionStatus.isConnected {
            connectedView
        } else {
            SetupView(appState: appState)
        }
    }

    private var connectedView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Status
            Label(appState.connectionStatus.label, systemImage: "circle.fill")
                .font(.caption)
                .foregroundStyle(.green)

            Divider()

            // Next meeting
            if let event = appState.nextEvent, let minutes = appState.minutesUntilNext {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Próxima reunião:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(event.title)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    Text("em \(minutes) min")
                        .font(.caption)
                        .foregroundStyle(.orange)

                    if let location = event.location {
                        Text(location)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let url = event.conferenceUrl {
                        Link("Entrar na reunião", destination: URL(string: url)!)
                            .font(.caption)
                    }
                }
            } else {
                Text("Sem reuniões próximas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Reminder minutes picker
            HStack {
                Text("Avisar antes:")
                    .font(.caption)
                Spacer()
                Picker("", selection: Binding(
                    get: { appState.reminderMinutes },
                    set: { newValue in
                        Task { await appState.updateReminderMinutes(newValue) }
                    }
                )) {
                    Text("5 min").tag(5)
                    Text("10 min").tag(10)
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                }
                .pickerStyle(.menu)
                .frame(width: 80)
            }

            // Launch at login
            LaunchAtLoginToggle()

            Divider()

            Button("Desconectar") {
                appState.disconnect()
            }
            .font(.caption)

            Button("Sair") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 240)
    }
}

struct LaunchAtLoginToggle: View {
    @State private var launchAtLogin = false

    var body: some View {
        Toggle("Abrir com o sistema", isOn: $launchAtLogin)
            .font(.caption)
            .onChange(of: launchAtLogin) { _, newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    launchAtLogin = !newValue
                }
            }
            .onAppear {
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
    }
}
