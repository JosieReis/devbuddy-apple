import AppKit

@MainActor
final class AirplaneAnimationController {
    static let shared = AirplaneAnimationController()

    private var activeWindow: AirplaneOverlayWindow?

    private init() {}

    func triggerAnimation(message: String, title: String) {
        // Don't stack animations
        if activeWindow != nil {
            print("[Airplane] Animation already active, skipping")
            return
        }

        guard let screen = NSScreen.main else {
            print("[Airplane] No main screen found")
            return
        }

        print("[Airplane] Triggering animation: \(message) — \(title)")

        let window = AirplaneOverlayWindow(screen: screen)
        activeWindow = window

        window.showAnimation(message: message, title: title)

        // Safety timeout: dismiss after 5 minutes if user doesn't click "visto"
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { [weak self] in
            self?.activeWindow?.orderOut(nil)
            self?.activeWindow = nil
        }
    }
}
