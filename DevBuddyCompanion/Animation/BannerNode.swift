import SpriteKit

final class BannerNode: SKNode {
    init(message: String, title: String) {
        super.init()

        let padding: CGFloat = 16
        let bannerHeight: CGFloat = 56
        let fontSize: CGFloat = 18
        let titleFontSize: CGFloat = 13

        // Measure text to size the banner
        let messageWidth = (message as NSString).size(
            withAttributes: [.font: NSFont.systemFont(ofSize: fontSize, weight: .bold)]
        ).width
        let titleWidth = (title as NSString).size(
            withAttributes: [.font: NSFont.systemFont(ofSize: titleFontSize, weight: .medium)]
        ).width
        let bannerWidth = max(messageWidth, titleWidth) + padding * 2 + 20

        // Rope connecting airplane to banner
        let ropeLength: CGFloat = 30
        let rope = SKShapeNode()
        let ropePath = CGMutablePath()
        ropePath.move(to: CGPoint(x: 0, y: 0))
        ropePath.addQuadCurve(
            to: CGPoint(x: -ropeLength, y: -8),
            control: CGPoint(x: -ropeLength / 2, y: 5)
        )
        rope.path = ropePath
        rope.strokeColor = SKColor(white: 0.3, alpha: 1)
        rope.lineWidth = 2
        rope.lineCap = .round
        addChild(rope)

        // Banner background
        let bannerRect = CGRect(
            x: -ropeLength - bannerWidth,
            y: -bannerHeight / 2 - 8,
            width: bannerWidth,
            height: bannerHeight
        )
        let bannerBg = SKShapeNode(rect: bannerRect, cornerRadius: 6)
        bannerBg.fillColor = SKColor.white
        bannerBg.strokeColor = SKColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1)
        bannerBg.lineWidth = 3
        addChild(bannerBg)

        // Red accent stripe at top of banner
        let stripeRect = CGRect(
            x: bannerRect.minX,
            y: bannerRect.maxY - 6,
            width: bannerWidth,
            height: 6
        )
        let stripe = SKShapeNode(rect: stripeRect, cornerRadius: 6)
        stripe.fillColor = SKColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1)
        stripe.strokeColor = SKColor.clear
        addChild(stripe)

        // Message text (main line)
        let messageLabel = SKLabelNode(text: message)
        messageLabel.fontName = "AvenirNext-Bold"
        messageLabel.fontSize = fontSize
        messageLabel.fontColor = SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.verticalAlignmentMode = .center
        messageLabel.position = CGPoint(
            x: bannerRect.midX,
            y: bannerRect.midY + (title.isEmpty ? 0 : 8)
        )
        addChild(messageLabel)

        // Title text (subtitle)
        if !title.isEmpty {
            let titleLabel = SKLabelNode(text: title)
            titleLabel.fontName = "AvenirNext-Medium"
            titleLabel.fontSize = titleFontSize
            titleLabel.fontColor = SKColor(white: 0.4, alpha: 1)
            titleLabel.horizontalAlignmentMode = .center
            titleLabel.verticalAlignmentMode = .center
            titleLabel.position = CGPoint(
                x: bannerRect.midX,
                y: bannerRect.midY - 10
            )
            addChild(titleLabel)
        }

        // Small triangular tail on the right side of banner (pennant style)
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: bannerRect.minX - 12, y: bannerRect.midY + 8))
        tailPath.addLine(to: CGPoint(x: bannerRect.minX, y: bannerRect.midY))
        tailPath.addLine(to: CGPoint(x: bannerRect.minX - 12, y: bannerRect.midY - 8))
        tailPath.closeSubpath()
        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = SKColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1)
        tail.strokeColor = .clear
        addChild(tail)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = BannerNode(message: "", title: "")
        return copy
    }
}
