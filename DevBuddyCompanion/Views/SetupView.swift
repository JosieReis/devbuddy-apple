import SwiftUI

struct SetupView: View {
    @ObservedObject var appState: AppState
    @State private var tokenInput: String = ""
    @State private var importSecretInput: String = ""
    @State private var isConnecting = false

    private var hasExistingImportSecret: Bool {
        KeychainService.loadImportSecret() != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("DevBuddy Companion", systemImage: "airplane")
                .font(.headline)

            Divider()

            Text(String(localized: "setup.instructions"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(String(localized: "setup.openSettings")) {
                if let url = URL(string: "\(APIEndpoint.baseURL)/settings") {
                    NSWorkspace.shared.open(url)
                }
            }
            .font(.caption)

            Divider()

            // Token field
            Text(String(localized: "setup.pasteToken"))
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("eyJhbG...", text: $tokenInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(.caption, design: .monospaced))

            // Import secret field
            Text(String(localized: "setup.importSecretLabel"))
                .font(.caption)
                .foregroundStyle(.secondary)

            SecureField(
                String(localized: "setup.importSecretPlaceholder"),
                text: $importSecretInput
            )
            .textFieldStyle(.roundedBorder)
            .font(.system(.caption, design: .monospaced))

            if case .error(let message) = appState.connectionStatus {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button(action: {
                isConnecting = true
                Task {
                    // Save import secret if provided
                    if !importSecretInput.isEmpty {
                        try? KeychainService.saveImportSecret(importSecretInput)
                    }
                    await appState.connect(with: tokenInput)
                    isConnecting = false
                    if appState.connectionStatus.isConnected {
                        tokenInput = ""
                        importSecretInput = ""
                    }
                }
            }) {
                HStack {
                    if isConnecting {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(String(localized: "setup.connect"))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(tokenInput.isEmpty || isConnecting)
        }
        .padding()
        .frame(width: 280)
    }
}
