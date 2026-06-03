import AppKit
import SpriteKit

final class AirplaneOverlayWindow: NSWindow {
    private var skView: SKView?

    convenience init(screen: NSScreen) {
        // Use right quarter of screen for the balloon area
        let width: CGFloat = 300
        let frame = CGRect(
            x: screen.frame.maxX - width,
            y: screen.frame.minY,
            width: width,
            height: screen.frame.height
        )

        self.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.hasShadow = false
    }

    func showAnimation(message: String, title: String) {
        let view = SKView(frame: contentView!.bounds)
        view.allowsTransparency = true
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        contentView?.addSubview(view)
        self.skView = view

        let scene = AirplaneScene(size: view.bounds.size)
        scene.backgroundColor = .clear
        scene.scaleMode = .resizeFill
        scene.onAnimationComplete = { [weak self] in
            DispatchQueue.main.async {
                self?.orderOut(nil)
            }
        }

        view.presentScene(scene)
        orderFront(nil)

        scene.flyAirplane(message: message, title: title)
    }
}
