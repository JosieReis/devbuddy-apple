import SpriteKit

final class AirplaneScene: SKScene {
    var onAnimationComplete: (() -> Void)?
    private var balloonNode: SKNode?
    private var dismissButton: SKShapeNode?

    func flyAirplane(message: String, title: String) {
        let balloon = createBalloonWithBanner(message: message, title: title)
        balloon.setScale(0.35)
        self.balloonNode = balloon

        // Start position: top-right corner, just above screen
        let rightMargin: CGFloat = 120
        let startX = size.width - rightMargin
        let startY = size.height + 200
        balloon.position = CGPoint(x: startX, y: startY)
        balloon.zPosition = 100
        addChild(balloon)

        // Target: descend to 1/4 height from top (right side)
        let quarterHeight = size.height * 0.75
        let bounceBottom = quarterHeight - 30
        let restY = size.height - 80 // final resting position near top

        // Phase 1: Descend slowly (3 seconds)
        let descend = SKAction.moveTo(y: quarterHeight, duration: 3.0)
        descend.timingMode = .easeIn

        // Phase 2: Bounce (hit bottom of 1/4 zone, bounce back up)
        let bounceDown = SKAction.moveTo(y: bounceBottom, duration: 0.2)
        bounceDown.timingMode = .easeIn
        let bounceUp1 = SKAction.moveTo(y: quarterHeight + 40, duration: 0.3)
        bounceUp1.timingMode = .easeOut
        let bounceDown2 = SKAction.moveTo(y: quarterHeight, duration: 0.2)
        bounceDown2.timingMode = .easeIn
        let bounceUp2 = SKAction.moveTo(y: quarterHeight + 15, duration: 0.2)
        bounceUp2.timingMode = .easeOut
        let bounceSettle = SKAction.moveTo(y: quarterHeight, duration: 0.15)

        let bounce = SKAction.sequence([bounceDown, bounceUp1, bounceDown2, bounceUp2, bounceSettle])

        // Phase 3: Float back up to top-right corner (2 seconds)
        let floatUp = SKAction.moveTo(y: restY, duration: 2.0)
        floatUp.timingMode = .easeInEaseOut

        // Gentle swaying throughout
        let swayRight = SKAction.moveBy(x: 8, y: 0, duration: 1.5)
        swayRight.timingMode = .easeInEaseOut
        let swayLeft = SKAction.moveBy(x: -8, y: 0, duration: 1.5)
        swayLeft.timingMode = .easeInEaseOut
        let sway = SKAction.repeatForever(SKAction.sequence([swayRight, swayLeft]))

        balloon.run(sway)

        // Run phases sequentially
        let sequence = SKAction.sequence([
            descend,
            bounce,
            SKAction.wait(forDuration: 0.3),
            floatUp,
            SKAction.run { [weak self] in
                self?.showDismissButton(at: CGPoint(x: startX, y: restY), balloon: balloon)
            },
        ])

        balloon.run(sequence)
    }

    private func showDismissButton(at position: CGPoint, balloon: SKNode) {
        // "visto" button below the balloon
        let buttonWidth: CGFloat = 60
        let buttonHeight: CGFloat = 24

        let button = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 12)
        button.fillColor = SKColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 0.9)
        button.strokeColor = SKColor(red: 0.15, green: 0.6, blue: 0.35, alpha: 1)
        button.lineWidth = 1
        button.position = CGPoint(x: position.x, y: position.y - 80)
        button.zPosition = 101
        button.name = "dismissButton"

        let label = SKLabelNode(text: "visto")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 12
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        button.addChild(label)

        addChild(button)
        self.dismissButton = button

        // Subtle pulse animation on button
        let scaleUp = SKAction.scale(to: 1.08, duration: 0.6)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.6)
        scaleDown.timingMode = .easeInEaseOut
        button.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodes = self.nodes(at: location)

        if nodes.contains(where: { $0.name == "dismissButton" || $0.parent?.name == "dismissButton" }) {
            // Fade out balloon and button, then complete
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let floatAway = SKAction.moveBy(x: 0, y: 100, duration: 0.3)
            let dismiss = SKAction.group([fadeOut, floatAway])

            balloonNode?.run(dismiss)
            dismissButton?.run(fadeOut) { [weak self] in
                self?.balloonNode?.removeFromParent()
                self?.dismissButton?.removeFromParent()
                self?.onAnimationComplete?()
            }
        }
    }

    private func createBalloonWithBanner(message: String, title: String) -> SKNode {
        let container = SKNode()

        // Load balloon image
        if let image = NSImage(contentsOfFile: Bundle.main.resourcePath?.appending("/balloon.png") ?? "") ??
            NSImage(contentsOfFile: "\(FileManager.default.currentDirectoryPath)/DevBuddyCompanion/Animation/balloon.png") ??
            loadBalloonFromPackage() {
            let texture = SKTexture(image: image)
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: 300, height: 450)
            container.addChild(sprite)
        } else {
            // Fallback: draw balloon shape
            let balloonShape = createFallbackBalloon()
            container.addChild(balloonShape)
        }

        // Banner hanging below balloon
        let bannerNode = createNotificationBanner(message: message, title: title)
        bannerNode.position = CGPoint(x: 0, y: -260)
        container.addChild(bannerNode)

        return container
    }

    private func loadBalloonFromPackage() -> NSImage? {
        // Try loading from bundle resources first, then from source directory
        if let bundled = Bundle.main.image(forResource: "balloon") {
            return bundled
        }
        // Fallback: load from source directory relative to executable
        let executableURL = Bundle.main.executableURL?.deletingLastPathComponent()
        let sourcePath = executableURL?
            .appendingPathComponent("DevBuddyCompanion/Animation/balloon.png")
        if let path = sourcePath?.path, let image = NSImage(contentsOfFile: path) {
            return image
        }
        return nil
    }

    private func createNotificationBanner(message: String, title: String) -> SKNode {
        let node = SKNode()

        let padding: CGFloat = 12
        let fontSize: CGFloat = 14
        let titleFontSize: CGFloat = 11

        let messageWidth = (message as NSString).size(
            withAttributes: [.font: NSFont.systemFont(ofSize: fontSize, weight: .bold)]
        ).width
        let titleWidth = (title as NSString).size(
            withAttributes: [.font: NSFont.systemFont(ofSize: titleFontSize, weight: .medium)]
        ).width
        let bannerWidth = min(max(messageWidth, titleWidth) + padding * 2 + 16, 280)
        let bannerHeight: CGFloat = title.isEmpty ? 36 : 48

        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: bannerWidth, height: bannerHeight), cornerRadius: 8)
        bg.fillColor = SKColor(white: 0.12, alpha: 0.92)
        bg.strokeColor = SKColor(white: 0.3, alpha: 0.5)
        bg.lineWidth = 1
        node.addChild(bg)

        // Message
        let messageLabel = SKLabelNode(text: message)
        messageLabel.fontName = "AvenirNext-Bold"
        messageLabel.fontSize = fontSize
        messageLabel.fontColor = .white
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.verticalAlignmentMode = .center
        messageLabel.position = CGPoint(x: 0, y: title.isEmpty ? 0 : 7)
        node.addChild(messageLabel)

        // Title
        if !title.isEmpty {
            let titleLabel = SKLabelNode(text: title)
            titleLabel.fontName = "AvenirNext-Medium"
            titleLabel.fontSize = titleFontSize
            titleLabel.fontColor = SKColor(white: 0.7, alpha: 1)
            titleLabel.horizontalAlignmentMode = .center
            titleLabel.verticalAlignmentMode = .center
            titleLabel.position = CGPoint(x: 0, y: -9)
            node.addChild(titleLabel)
        }

        // Ropes from balloon to banner
        let ropeLeft = SKShapeNode()
        let leftPath = CGMutablePath()
        leftPath.move(to: CGPoint(x: -bannerWidth / 2 + 10, y: bannerHeight / 2))
        leftPath.addLine(to: CGPoint(x: -20, y: bannerHeight / 2 + 30))
        ropeLeft.path = leftPath
        ropeLeft.strokeColor = SKColor(white: 0.5, alpha: 0.6)
        ropeLeft.lineWidth = 1
        node.addChild(ropeLeft)

        let ropeRight = SKShapeNode()
        let rightPath = CGMutablePath()
        rightPath.move(to: CGPoint(x: bannerWidth / 2 - 10, y: bannerHeight / 2))
        rightPath.addLine(to: CGPoint(x: 20, y: bannerHeight / 2 + 30))
        ropeRight.path = rightPath
        ropeRight.strokeColor = SKColor(white: 0.5, alpha: 0.6)
        ropeRight.lineWidth = 1
        node.addChild(ropeRight)

        return node
    }

    private func createFallbackBalloon() -> SKNode {
        let container = SKNode()

        // Balloon body (ellipse)
        let body = SKShapeNode(ellipseOf: CGSize(width: 120, height: 160))
        body.fillColor = SKColor(red: 0.9, green: 0.5, blue: 0.6, alpha: 1)
        body.strokeColor = SKColor(red: 0.8, green: 0.4, blue: 0.5, alpha: 1)
        body.lineWidth = 2
        body.position = CGPoint(x: 0, y: 40)
        container.addChild(body)

        // Stripes
        for i in stride(from: -40, through: 40, by: 20) {
            let stripe = SKShapeNode(rectOf: CGSize(width: 3, height: 140))
            stripe.fillColor = SKColor.white.withAlphaComponent(0.4)
            stripe.strokeColor = .clear
            stripe.position = CGPoint(x: CGFloat(i), y: 40)
            container.addChild(stripe)
        }

        // Basket
        let basket = SKShapeNode(rectOf: CGSize(width: 40, height: 25), cornerRadius: 3)
        basket.fillColor = SKColor(red: 0.6, green: 0.45, blue: 0.3, alpha: 1)
        basket.strokeColor = SKColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1)
        basket.lineWidth = 1.5
        basket.position = CGPoint(x: 0, y: -60)
        container.addChild(basket)

        return container
    }
}
