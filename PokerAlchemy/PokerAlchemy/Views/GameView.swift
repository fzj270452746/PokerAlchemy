import SwiftUI
import SpriteKit
import Combine

private class PAGameContext: ObservableObject {
    let model = PAGameModel()
    let scene = PAGameScene()
    let bridge: GameSceneBridge

    init() {
        bridge = GameSceneBridge(model: model, scene: scene)
    }
}

struct PAGameView: View {
    @StateObject private var ctx = PAGameContext()
    @State private var showWin = false
    @State private var showLose = false
    @State private var showReshuffle = false
    @State private var showResetConfirm = false
    @State private var showHelp = false

    @State private var draggingCard: PACard? = nil
    @State private var dragLocation: CGPoint = .zero
    @State private var boardFrame: CGRect = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PATheme.gradientBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    topHUD
                    boardArea(geo: geo)
                    handArea(geo: geo)
                    bottomBar
                }

                if let card = draggingCard {
                    PAHandCardView(card: card, isDragging: true)
                        .position(dragLocation)
                        .allowsHitTesting(false)
                        .zIndex(100)
                }

                if showWin { winOverlay }
                if showLose { loseOverlay }
                if showReshuffle { reshuffleConfirm }
                if showResetConfirm { resetConfirm }
                if showHelp { PAHelpSheet { showHelp = false } }
            }
        }
        .onReceive(ctx.model.$gameState) { state in
            showWin = state == .win
            showLose = state == .lose
        }
    }

    // MARK: - Top HUD
    private var topHUD: some View {
        HStack(spacing: 0) {
            // Steam bar with asset textures
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(PATheme.accentTeal)
                    Text("STEAM")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(PATheme.textSecondary)
                }
                ZStack(alignment: .leading) {
                    Image("steam_bar_bg")
                        .resizable()
                        .frame(width: 120, height: 14)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(white: 0.3), lineWidth: 0.5))
                    Image("steam_bar_fill")
                        .resizable()
                        .frame(width: max(6, 120 * CGFloat(min(ctx.model.steam, 200)) / 200.0), height: 14)
                        .clipShape(Capsule())
                        .animation(.easeInOut(duration: 0.3), value: ctx.model.steam)
                }
                Text("\(ctx.model.steam)")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundStyle(steamColor)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("LEVEL \(ctx.model.currentLevelID)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(PATheme.textSecondary)
                Text("\(ctx.model.completedRecipesCount)/\(ctx.model.allRecipesCount)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(PATheme.accent)
                Text("Recipes")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(PATheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("CORES")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(PATheme.textSecondary)
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundStyle(PATheme.accent)
                }
                Text("\(ctx.model.steamCore)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(PATheme.accent)
                Text("Hand: \(ctx.model.hand.count)/7")
                    .font(.system(size: 9))
                    .foregroundStyle(PATheme.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(
            PATheme.surface
                .overlay(
                    Rectangle()
                        .fill(PATheme.accentTeal.opacity(0.15))
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }

    private var steamColor: Color {
        let s = ctx.model.steam
        if s > 80 { return PATheme.accentTeal }
        if s > 40 { return PATheme.accent }
        return PATheme.danger
    }

    // MARK: - Board
    private func boardArea(geo: GeometryProxy) -> some View {
        GeometryReader { boardGeo in
            SpriteView(scene: ctx.scene, options: [.allowsTransparency])
                .frame(width: boardGeo.size.width, height: boardGeo.size.height)
                .clipped()
                .background(Color.clear)
                .overlay(alignment: .top) {
                    if draggingCard != nil {
                        Text("Release to place")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(PATheme.accentTeal.opacity(0.35)))
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut(duration: 0.2), value: draggingCard != nil)
                    }
                }
                .background(
                    Color.clear.onAppear {
                        boardFrame = boardGeo.frame(in: .global)
                    }
                )
                .onAppear {
                    boardFrame = boardGeo.frame(in: .global)
                    configureScene(size: boardGeo.size)
                }
                .onChange(of: boardGeo.size) { newSize in
                    boardFrame = boardGeo.frame(in: .global)
                    configureScene(size: newSize)
                }
        }
    }

    private func configureScene(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        ctx.scene.size = size
        ctx.scene.scaleMode = .resizeFill
        ctx.scene.backgroundColor = SKColor.clear
        ctx.scene.gameModel = ctx.model
        ctx.scene.paDelegate = ctx.bridge
    }

    private func scenePoint(from globalPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: globalPoint.x - boardFrame.minX,
            y: ctx.scene.size.height - (globalPoint.y - boardFrame.minY)
        )
    }

    // MARK: - Hand
    private func handArea(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(colors: [Color(red:0.6,green:0.45,blue:0.1).opacity(0.6), Color(red:0.4,green:0.3,blue:0.05).opacity(0.4)],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .frame(height: 1.5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ctx.model.hand) { card in
                        PAHandCardView(card: card, isDragging: draggingCard?.id == card.id)
                            .gesture(
                                DragGesture(minimumDistance: 4, coordinateSpace: .global)
                                    .onChanged { value in
                                        if draggingCard == nil || draggingCard?.id != card.id {
                                            draggingCard = card
                                            ctx.scene.pendingCard = card
                                        }
                                        dragLocation = value.location
                                        ctx.scene.updateDragHover(at: scenePoint(from: value.location))
                                    }
                                    .onEnded { value in
                                        guard let card = draggingCard else { return }
                                        ctx.scene.handleDrop(card: card, at: scenePoint(from: value.location))
                                        ctx.scene.updateDragHover(at: nil)
                                        draggingCard = nil
                                        ctx.scene.pendingCard = nil
                                    }
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
            }
            .frame(height: 98)
        }
        .background(
            ZStack {
                PATheme.surface.opacity(0.97)
                // Subtle golden sheen at top
                LinearGradient(
                    colors: [Color(red:0.55,green:0.42,blue:0.08).opacity(0.12), Color.clear],
                    startPoint: .top, endPoint: .bottom
                )
            }
        )
    }

    private let bottomBarHeight: CGFloat = 60

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    showReshuffle = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.2.circlepath")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Reshuffle")
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Text("−30")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(PATheme.accentTeal.opacity(0.8))
                            .lineLimit(1)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(ctx.model.steam >= 30 ? .white : Color(white: 0.4))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(ctx.model.steam >= 30 ? PATheme.surfaceHigh : Color(white: 0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(ctx.model.steam >= 30
                                            ? PATheme.accentTeal.opacity(0.5)
                                            : Color(white: 0.2), lineWidth: 1)
                            )
                    )
                }
                .disabled(ctx.model.steam < 30)

                Button {
                    showHelp = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 13, weight: .semibold))
                        Text("How to Play")
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(PATheme.surfaceHigh)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(PATheme.accentTeal.opacity(0.5), lineWidth: 1)
                            )
                    )
                }

                Button {
                    showResetConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Reset Forge")
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.35, green: 0.1, blue: 0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 0.95, green: 0.35, blue: 0.35).opacity(0.8), lineWidth: 1)
                            )
                    )
                }

                let totalCont = ctx.model.board.map(\.contamination).reduce(0, +)
                if totalCont > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                        Text("Contamination: \(totalCont)")
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(Color(red: 1, green: 0.55, blue: 0.15))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.4, green: 0.15, blue: 0.05).opacity(0.6))
                    )
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: bottomBarHeight)
        }
        .frame(height: bottomBarHeight)
        .background(PATheme.surface)
    }

    // MARK: - Overlays
    private var winOverlay: some View {
        ZStack {
            // win_effect as fullscreen background
            Image("win_effect")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.35)
                .allowsHitTesting(false)

            PAAlertView(
                title: "✦ Victory ✦",
                message: "All alchemical recipes fulfilled!\nSteam Cores earned: \(ctx.model.steamCore)",
                buttons: [
                    ("Next Level", {
                        showWin = false
                        let next = ctx.model.currentLevelID + 1
                        let maxLevel = PALevelData.shared.levels.count
                        ctx.model.loadLevel(id: min(next, maxLevel))
                        ctx.scene.refreshBoard()
                        ctx.scene.refreshHand()
                    }),
                    ("Menu", { showWin = false })
                ]
            )
        }
    }

    private var loseOverlay: some View {
        PAAlertView(
            title: "☠ Steam Depleted",
            message: "Your forge has run cold.\nRestart and try again.",
            buttons: [
                ("Retry", {
                    showLose = false
                    ctx.model.loadLevel(id: ctx.model.currentLevelID)
                    ctx.scene.refreshBoard()
                    ctx.scene.refreshHand()
                }),
                ("Menu", { showLose = false })
            ]
        )
    }

    private var reshuffleConfirm: some View {
        PAAlertView(
            title: "Reshuffle?",
            message: "Consume 30 Steam to reshuffle your hand and pool.",
            buttons: [
                ("Confirm", {
                    showReshuffle = false
                    _ = ctx.model.reshufflePool(costSteam: 30)
                    ctx.scene.refreshHand()
                    ctx.scene.updateSteamBar()
                }),
                ("Cancel", { showReshuffle = false })
            ]
        )
    }

    private var resetConfirm: some View {
        PAAlertView(
            title: "Reset Forge?",
            message: "This will restart the current Forge level and clear current board/hand progress.",
            buttons: [
                ("Reset", {
                    showResetConfirm = false
                    ctx.model.loadLevel(id: ctx.model.currentLevelID)
                    ctx.scene.refreshBoard()
                    ctx.scene.refreshHand()
                    ctx.scene.updateSteamBar()
                }),
                ("Cancel", { showResetConfirm = false })
            ]
        )
    }
}

// MARK: - Hand Card View
struct PAHandCardView: View {
    let card: PACard
    var isDragging: Bool = false

    var body: some View {
        ZStack {
            if case .poker(let c) = card {
                pokerCardFace(c)
            } else {
                // Steampunk leather texture background
                Image("card_back")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).fill(cardTint.opacity(0.38)))

                // Border + glow
                RoundedRectangle(cornerRadius: 11)
                    .stroke(isDragging ? Color.white : cardBorder, lineWidth: isDragging ? 2.5 : 1.5)
                    .shadow(color: (isDragging ? Color.white : cardGlow).opacity(0.55), radius: isDragging ? 12 : 7)

                // Card content
                VStack(spacing: 3) {
                    cardIcon
                    Text(subLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.8), radius: 1)
                }
            }
        }
        .frame(width: 58, height: 88)
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .opacity(isDragging ? 0.4 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isDragging)
    }

    @ViewBuilder
    private func pokerCardFace(_ c: PAPokerCard) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11)
                .fill(Color.white)
            RoundedRectangle(cornerRadius: 11)
                .stroke(Color(red: 0.85, green: 0.82, blue: 0.78), lineWidth: 1)
            RoundedRectangle(cornerRadius: 9)
                .stroke(Color(red: 0.93, green: 0.90, blue: 0.86), lineWidth: 0.8)
                .padding(2)

            VStack(spacing: 0) {
                HStack {
                    VStack(spacing: -2) {
                        Text(c.rank.display)
                            .font(.system(size: 11, weight: .bold, design: .serif))
                        Text(c.suit.symbol)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(c.suit.isRed ? Color(red: 0.82, green: 0.12, blue: 0.16) : .black)
                    Spacer()
                }
                Spacer()
                Text(c.suit.symbol)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(c.suit.isRed ? Color(red: 0.82, green: 0.12, blue: 0.16) : .black)
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: -2) {
                        Text(c.rank.display)
                            .font(.system(size: 11, weight: .bold, design: .serif))
                        Text(c.suit.symbol)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(c.suit.isRed ? Color(red: 0.82, green: 0.12, blue: 0.16) : .black)
                    .rotationEffect(.degrees(180))
                }
            }
            .padding(6)
        }
        .shadow(color: Color.black.opacity(0.22), radius: 4, y: 1.5)
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .stroke(isDragging ? Color(red: 0.25, green: 0.75, blue: 1.0) : Color.clear, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var cardIcon: some View {
        switch card {
        case .poker(let c):
            VStack(spacing: 0) {
                Text(c.rank.display)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(c.suit.isRed ? Color(red:1, green:0.3, blue:0.3) : Color.white)
                    .shadow(color: .black.opacity(0.8), radius: 2)
                Text(c.suit.symbol)
                    .font(.system(size: 14))
                    .foregroundStyle(c.suit.isRed ? Color(red:1, green:0.3, blue:0.3) : Color.white)
                    .shadow(color: .black.opacity(0.8), radius: 1)
            }
        case .element(let c):
            Image(c.element.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)
                .shadow(color: cardGlow.opacity(0.8), radius: 6)
        case .transmute(let c):
            VStack(spacing: 2) {
                Image("transmute_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .shadow(color: Color.purple.opacity(0.8), radius: 5)
                Text(c.delta >= 0 ? "+\(c.delta)" : "\(c.delta)")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color(red:0.88, green:0.65, blue:1.0))
                    .shadow(color: .black.opacity(0.8), radius: 1)
            }
        }
    }

    private var subLabel: String {
        switch card {
        case .poker(let c): return c.suit.rawValue.capitalized
        case .element(let c): return c.element.rawValue.capitalized
        case .transmute: return "Transmute"
        }
    }

    private var cardTint: Color {
        switch card {
        case .poker(let c): return c.suit.isRed ? Color(red:0.5, green:0.05, blue:0.05) : Color(red:0.05, green:0.1, blue:0.3)
        case .element(let c):
            switch c.element {
            case .fire: return Color(red:0.5, green:0.1, blue:0.0)
            case .water: return Color(red:0.0, green:0.15, blue:0.45)
            case .earth: return Color(red:0.05, green:0.25, blue:0.05)
            case .air: return Color(red:0.05, green:0.25, blue:0.25)
            }
        case .transmute: return Color(red:0.25, green:0.0, blue:0.4)
        }
    }

    private var cardBorder: Color {
        switch card {
        case .poker(let c): return c.suit.isRed ? Color(red:0.85,green:0.25,blue:0.25).opacity(0.9) : Color(red:0.6,green:0.7,blue:1.0).opacity(0.7)
        case .element(let c):
            switch c.element {
            case .fire: return Color(red:1,green:0.45,blue:0.1).opacity(0.9)
            case .water: return Color(red:0.1,green:0.65,blue:1).opacity(0.9)
            case .earth: return Color(red:0.35,green:0.75,blue:0.2).opacity(0.9)
            case .air: return Color(red:0.3,green:0.9,blue:0.85).opacity(0.9)
            }
        case .transmute: return Color(red:0.75,green:0.35,blue:1.0).opacity(0.9)
        }
    }

    private var cardGlow: Color {
        switch card {
        case .poker(let c): return c.suit.isRed ? .red : Color(red:0.4, green:0.6, blue:1.0)
        case .element(let c):
            switch c.element {
            case .fire: return .orange
            case .water: return .blue
            case .earth: return .green
            case .air: return Color(red:0.3, green:0.9, blue:0.85)
            }
        case .transmute: return .purple
        }
    }
}

// MARK: - Bridge delegate
private class GameSceneBridge: NSObject, PAGameSceneDelegate {
    let model: PAGameModel
    weak var scene: PAGameScene?

    init(model: PAGameModel, scene: PAGameScene) {
        self.model = model
        self.scene = scene
    }

    func sceneDidRequestPlacement(card: PACard, nodeID: UUID) {
        guard let node = model.board.first(where: { $0.id == nodeID }) else { return }
        if model.placeCard(card: card, at: node) {
            scene?.refreshBoard()
            scene?.refreshHand()
            scene?.updateSteamBar()
        }
    }

    func sceneDidRequestReshuffle() {
        _ = model.reshufflePool(costSteam: 30)
        scene?.refreshHand()
    }
}
