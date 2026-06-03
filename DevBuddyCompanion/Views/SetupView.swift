import SwiftUI

struct SetupView: View {
    @ObservedObject var appState: AppState
    @State private var tokenInput: String = ""
    @State private var isConnecting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("DevBuddy Companion", systemImage: "airplane")
                .font(.headline)

            Divider()

            Text("Cole o JWT token (cookie 'session' do DevBuddy):")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("eyJhbG...", text: $tokenInput)
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
                    await appState.connect(with: tokenInput)
                    isConnecting = false
                    if appState.connectionStatus.isConnected {
                        tokenInput = ""
                    }
                }
            }) {
                HStack {
                    if isConnecting {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("Conectar")
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
