import SpriteKit
import SwiftUI
import UIKit
import Combine

protocol PAGameSceneDelegate: AnyObject {
    func sceneDidRequestPlacement(card: PACard, nodeID: UUID)
    func sceneDidRequestReshuffle()
}

class PAGameScene: SKScene {
    weak var paDelegate: PAGameSceneDelegate?
    var gameModel: PAGameModel? {
        didSet {
            subscribeToModel()
            refreshBoard()
        }
    }

    // Set by SwiftUI when user selects a hand card
    var pendingCard: PACard? {
        didSet { updatePendingHighlight() }
    }

    private var cancellables = Set<AnyCancellable>()
    private var hexNodeSprites: [UUID: SKSpriteNode] = [:]
    private var hoveredNodeID: UUID? = nil
    private let baseHexSize: CGFloat = 36
    private var hexSize: CGFloat = 36

    override var size: CGSize {
        didSet {
            guard oldValue != size else { return }
            refreshBackgroundLayout()
            refreshBoard()
        }
    }

    private func subscribeToModel() {
        cancellables.removeAll()
        guard let model = gameModel else { return }
        model.$board
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshBoard() }
            .store(in: &cancellables)
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor.clear
        setupBackground()
        refreshBoard()
    }

    private func setupBackground() {
        if let emitter = SKEmitterNode(fileNamed: "gear_particle.sks") {
            emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
            emitter.name = "gearParticle"
            emitter.zPosition = -10
            addChild(emitter)
        }
    }

    private func refreshBackgroundLayout() {
        childNode(withName: "gearParticle")?.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    func refreshBoard() {
        guard let model = gameModel else { return }
        hexNodeSprites.values.forEach { $0.removeFromParent() }
        hexNodeSprites = [:]
        hexSize = fittedHexSize(for: model.board)

        let centerX = size.width / 2
        let centerY = size.height / 2

        for node in model.board {
            let pixel = PAHexGridHelper.axialToPixel(q: node.axialQ, r: node.axialR, size: hexSize)
            let pos = CGPoint(x: centerX + pixel.x, y: centerY - pixel.y)

            let sprite = SKSpriteNode(imageNamed: node.contamination > 0 ? "hex_node_contaminated" : "hex_node_base")
            sprite.size = CGSize(width: hexSize * 1.9, height: hexSize * 2.1)
            sprite.position = pos
            sprite.zPosition = CGFloat(node.axialR + 3) * 10
            sprite.name = node.id.uuidString
            addChild(sprite)
            hexNodeSprites[node.id] = sprite

            if let card = node.card {
                addCardFace(card, to: sprite)
            }
        }
        updatePendingHighlight()
    }

    private func fittedHexSize(for board: [PANode]) -> CGFloat {
        guard size.width > 0, size.height > 0, !board.isEmpty else { return baseHexSize }

        let baseBounds = boardBounds(for: board, hexSize: baseHexSize)
        let horizontalInset: CGFloat = 18
        let verticalInset: CGFloat = 14
        let availableWidth = max(1, size.width - horizontalInset * 2)
        let availableHeight = max(1, size.height - verticalInset * 2)
        let widthScale = availableWidth / max(1, baseBounds.width)
        let heightScale = availableHeight / max(1, baseBounds.height)

        return min(baseHexSize, baseHexSize * min(widthScale, heightScale))
    }

    private func boardBounds(for board: [PANode], hexSize: CGFloat) -> CGSize {
        let spriteWidth = hexSize * 1.9
        let spriteHeight = hexSize * 2.1
        let rects = board.map { node -> CGRect in
            let pixel = PAHexGridHelper.axialToPixel(q: node.axialQ, r: node.axialR, size: hexSize)
            return CGRect(
                x: pixel.x - spriteWidth / 2,
                y: pixel.y - spriteHeight / 2,
                width: spriteWidth,
                height: spriteHeight
            )
        }

        return rects.dropFirst().reduce(rects[0]) { $0.union($1) }.size
    }

    // Legacy stubs so GameView bridge still compiles
    func refreshHand() {}
    func updateSteamBar() {}

    func handleDrop(card: PACard, at scenePoint: CGPoint) {
        if let (nodeID, sprite) = hexNodeSprites.first(where: { $0.value.contains(scenePoint) }) {
            sprite.run(SKAction.sequence([
                SKAction.colorize(with: UIColor(red: 0.2, green: 1.0, blue: 0.6, alpha: 1), colorBlendFactor: 0.7, duration: 0.08),
                SKAction.colorize(withColorBlendFactor: 0, duration: 0.15)
            ]))
            paDelegate?.sceneDidRequestPlacement(card: card, nodeID: nodeID)
            pendingCard = nil
            hoveredNodeID = nil
            updatePendingHighlight()
        }
    }

    func updateDragHover(at scenePoint: CGPoint?) {
        guard pendingCard != nil else {
            hoveredNodeID = nil
            updatePendingHighlight()
            return
        }

        guard let scenePoint else {
            hoveredNodeID = nil
            updatePendingHighlight()
            return
        }

        hoveredNodeID = hexNodeSprites.first(where: { $0.value.contains(scenePoint) })?.key
        updatePendingHighlight()
    }

    private func addCardFace(_ card: PACard, to sprite: SKSpriteNode) {
        sprite.removeChildren(in: sprite.children.filter { $0.name == "cardFace" })
        let face = makeCardFaceNode(card)
        face.name = "cardFace"
        face.zPosition = 20
        sprite.addChild(face)
    }

    private func makeCardFaceNode(_ card: PACard) -> SKNode {
        let container = SKNode()
        switch card {
        case .poker(let c):
            let bg = SKShapeNode(path: cardHexPath(radius: hexSize * 0.75))
            bg.fillColor = UIColor(white: 0.95, alpha: 0.92)
            bg.strokeColor = c.suit.isRed
                ? UIColor(red: 0.95, green: 0.24, blue: 0.3, alpha: 0.85)
                : UIColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 0.85)
            bg.lineWidth = 1.5
            bg.glowWidth = 1.2
            bg.zPosition = 1
            container.addChild(bg)
            let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            label.text = c.rank.display + c.suit.symbol
            label.fontSize = 14
            label.fontColor = c.suit.isRed ? UIColor(red: 0.9, green: 0.1, blue: 0.2, alpha: 1) : .black
            label.verticalAlignmentMode = .center
            label.zPosition = 2
            container.addChild(label)

        case .element(let c):
            let img = SKSpriteNode(imageNamed: c.element.imageName)
            img.size = CGSize(width: hexSize * 1.0, height: hexSize * 1.0)
            img.zPosition = 2
            container.addChild(img)

        case .transmute(let c):
            let img = SKSpriteNode(imageNamed: "transmute_icon")
            img.size = CGSize(width: hexSize * 0.9, height: hexSize * 0.9)
            img.zPosition = 2
            container.addChild(img)
            let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            label.text = c.delta >= 0 ? "+\(c.delta)" : "\(c.delta)"
            label.fontSize = 11
            label.fontColor = UIColor(red: 0.85, green: 0.6, blue: 1.0, alpha: 1)
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: -(hexSize * 0.6))
            label.zPosition = 2
            container.addChild(label)
        }
        return container
    }

    private func cardHexPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for index in 0..<6 {
            let angle = CGFloat.pi / 2 + CGFloat(index) * CGFloat.pi / 3
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    // MARK: - Pending card highlight

    private func updatePendingHighlight() {
        guard let model = gameModel, pendingCard != nil else {
            hexNodeSprites.values.forEach { sprite in
                sprite.removeAction(forKey: "hoverPulse")
                sprite.run(SKAction.colorize(withColorBlendFactor: 0, duration: 0.12))
                sprite.run(SKAction.scale(to: 1.0, duration: 0.12))
                if let outline = sprite.childNode(withName: "hoverOutline") {
                    outline.removeFromParent()
                }
            }
            return
        }

        for (id, sprite) in hexNodeSprites {
            guard let node = model.board.first(where: { $0.id == id }), node.card == nil else {
                sprite.removeAction(forKey: "hoverPulse")
                sprite.run(SKAction.colorize(withColorBlendFactor: 0, duration: 0.12))
                sprite.run(SKAction.scale(to: 1.0, duration: 0.12))
                if let outline = sprite.childNode(withName: "hoverOutline") {
                    outline.removeFromParent()
                }
                continue
            }

            if id == hoveredNodeID {
                // Single hovered hex: strong highlight
                sprite.removeAction(forKey: "hoverPulse")
                sprite.run(SKAction.colorize(with: UIColor(red: 0.35, green: 1.0, blue: 0.95, alpha: 1), colorBlendFactor: 0.55, duration: 0.08))
                sprite.run(SKAction.scale(to: 1.08, duration: 0.08))

                if sprite.childNode(withName: "hoverOutline") == nil {
                    let outline = SKShapeNode(path: UIBezierPath(roundedRect: CGRect(x: -hexSize * 0.95, y: -hexSize * 1.05, width: hexSize * 1.9, height: hexSize * 2.1), cornerRadius: 6).cgPath)
                    outline.name = "hoverOutline"
                    outline.strokeColor = UIColor(red: 0.5, green: 1.0, blue: 0.95, alpha: 0.95)
                    outline.lineWidth = 2.2
                    outline.glowWidth = 5
                    outline.fillColor = .clear
                    outline.zPosition = 5
                    sprite.addChild(outline)
                }
            } else {
                // Non-hovered available hex: reset
                sprite.removeAction(forKey: "hoverPulse")
                sprite.run(SKAction.colorize(withColorBlendFactor: 0, duration: 0.12))
                sprite.run(SKAction.scale(to: 1.0, duration: 0.12))
                if let outline = sprite.childNode(withName: "hoverOutline") {
                    outline.removeFromParent()
                }
            }
        }
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let card = pendingCard else { return }
        let loc = touch.location(in: self)
        if let (nodeID, sprite) = hexNodeSprites.first(where: { $0.value.contains(loc) }) {
            // Flash confirmation
            sprite.run(SKAction.sequence([
                SKAction.colorize(with: UIColor(red: 0.2, green: 1.0, blue: 0.6, alpha: 1), colorBlendFactor: 0.7, duration: 0.08),
                SKAction.colorize(withColorBlendFactor: 0, duration: 0.15)
            ]))
            paDelegate?.sceneDidRequestPlacement(card: card, nodeID: nodeID)
            pendingCard = nil
        }
    }
}
