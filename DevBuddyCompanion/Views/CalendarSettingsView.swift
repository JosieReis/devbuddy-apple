import EventKit
import SwiftUI

struct CalendarSettingsView: View {
    @ObservedObject var appState: AppState
    @State private var settings = CalendarSyncSettings()
    @State private var importSecret: String = ""
    @State private var calendars: [EKCalendar] = []
    @State private var hasAccess = false
    @State private var isSyncing = false
    @State private var lastResult: ImportResult?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "calendarSettings.title"))
                .font(.headline)

            Divider()

            if !hasAccess {
                Text(String(localized: "calendarSettings.accessDenied"))
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if calendars.isEmpty {
                Text(String(localized: "calendarSettings.noCalendars"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(String(localized: "calendarSettings.calendars"))
                    .font(.caption)
                    .fontWeight(.semibold)

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(calendars, id: \.calendarIdentifier) { cal in
                            calendarRow(cal)
                        }
                    }
                }
                .frame(maxHeight: 160)
            }

            Divider()

            // Sync interval
            HStack {
                Text(String(localized: "calendarSettings.syncInterval"))
                    .font(.caption)
                Spacer()
                Picker("", selection: $settings.intervalMinutes) {
                    Text("5 min").tag(5)
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                    Text("60 min").tag(60)
                }
                .pickerStyle(.menu)
                .frame(width: 90)
            }

            // Days ahead
            HStack {
                Text(String(localized: "calendarSettings.daysAhead"))
                    .font(.caption)
                Spacer()
                Picker("", selection: $settings.daysAhead) {
                    Text("7").tag(7)
                    Text("14").tag(14)
                    Text("30").tag(30)
                    Text("60").tag(60)
                }
                .pickerStyle(.menu)
                .frame(width: 90)
            }

            // Import secret
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "calendarSettings.importSecret"))
                    .font(.caption)
                SecureField("", text: $importSecret)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
            }

            Divider()

            // Actions
            HStack {
                Button(String(localized: "calendarSettings.save")) {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button(String(localized: "calendarSettings.syncNow")) {
                    isSyncing = true
                    Task {
                        save()
                        await appState.syncNow()
                        isSyncing = false
                    }
                }
                .controlSize(.small)
                .disabled(isSyncing || settings.enabledCalendarIDs.isEmpty)

                if isSyncing {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            // Last sync info
            if let date = appState.lastSyncDate {
                let formatter = RelativeDateTimeFormatter()
                Text(String(localized: "calendarSettings.lastSync \(formatter.localizedString(for: date, relativeTo: Date()))"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 320)
        .task {
            await loadCalendars()
            importSecret = KeychainService.loadImportSecret() ?? ""
        }
    }

    private func calendarRow(_ cal: EKCalendar) -> some View {
        let isEnabled = Binding(
            get: { settings.enabledCalendarIDs.contains(cal.calendarIdentifier) },
            set: { newValue in
                if newValue {
                    settings.enabledCalendarIDs.insert(cal.calendarIdentifier)
                } else {
                    settings.enabledCalendarIDs.remove(cal.calendarIdentifier)
                }
            }
        )
        let alias = Binding(
            get: { settings.calendarAliases[cal.calendarIdentifier] ?? "" },
            set: { newValue in
                if newValue.isEmpty {
                    settings.calendarAliases.removeValue(forKey: cal.calendarIdentifier)
                } else {
                    settings.calendarAliases[cal.calendarIdentifier] = newValue
                }
            }
        )

        return HStack {
            Toggle(cal.title, isOn: isEnabled)
                .font(.caption)
                .frame(maxWidth: 140, alignment: .leading)

            TextField(String(localized: "calendarSettings.alias"), text: alias)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                .frame(width: 100)
        }
    }

    private func loadCalendars() async {
        guard let syncService = appState.calendarSyncService else { return }
        hasAccess = await syncService.requestAccess()
        if hasAccess {
            calendars = syncService.discoverCalendars()
        }
    }

    private func save() {
        settings.save()
        if !importSecret.isEmpty {
            try? KeychainService.saveImportSecret(importSecret)
        }
        appState.startCalendarSync()
    }
}
