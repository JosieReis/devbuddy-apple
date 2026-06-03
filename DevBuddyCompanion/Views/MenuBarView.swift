import SwiftUI
import ServiceManagement

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @State private var showCalendarSettings = false

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
                    Text(String(localized: "menu.nextMeeting"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(event.title)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    Text(String(localized: "menu.inMinutes \(minutes)"))
                        .font(.caption)
                        .foregroundStyle(.orange)

                    if let location = event.location {
                        Text(location)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let url = event.conferenceUrl {
                        Link(String(localized: "menu.joinMeeting"), destination: URL(string: url)!)
                            .font(.caption)
                    }
                }
            } else {
                Text(String(localized: "menu.noMeetings"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Reminder minutes picker
            HStack {
                Text(String(localized: "menu.remindBefore"))
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

            // Calendar sync status
            if let syncDate = appState.lastSyncDate {
                let formatter = RelativeDateTimeFormatter()
                Text(String(localized: "menu.lastSync \(formatter.localizedString(for: syncDate, relativeTo: Date()))"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Button(String(localized: "menu.syncNow")) {
                Task { await appState.syncNow() }
            }
            .font(.caption)

            Button(String(localized: "menu.calendarSettings")) {
                showCalendarSettings = true
            }
            .font(.caption)
            .popover(isPresented: $showCalendarSettings) {
                CalendarSettingsView(appState: appState)
            }

            // Launch at login
            LaunchAtLoginToggle()

            Divider()

            Button(String(localized: "menu.disconnect")) {
                appState.disconnect()
            }
            .font(.caption)

            Button(String(localized: "menu.quit")) {
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
        Toggle(String(localized: "launch.atLogin"), isOn: $launchAtLogin)
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
