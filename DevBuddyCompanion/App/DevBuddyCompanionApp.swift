import SwiftUI

@main
struct DevBuddyCompanionApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("DevBuddy", systemImage: appState.menuBarIcon) {
            MenuBarView(appState: appState)
                .task {
                    if !appState.connectionStatus.isConnected {
                        if let token = KeychainService.getToken() {
                            await appState.connect(with: token)
                        }
                    }
                }
        }
    }
}
