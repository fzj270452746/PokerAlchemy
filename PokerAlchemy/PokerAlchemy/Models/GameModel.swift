import Foundation
import Combine

class PAGameModel: ObservableObject {
    @Published var board: [PANode] = []
    @Published var hand: [PACard] = []
    @Published var cardPool: [PACard] = []
    @Published var steam: Int = 100
    @Published var steamCore: Int = 0
    @Published var completedRecipes: Set<Int> = []
    @Published var gameState: PAGameState = .playing
    @Published var currentLevelID: Int = 1
    @Published var lastReactionSteam: Int = 0

    private var levelRecipes: [PARecipePattern] = []
    private let maxHandSize = 7

    init() {
        loadLevel(id: PASaveManager.shared.currentLevelID)
    }

    func loadLevel(id: Int) {
        guard let config = PALevelData.shared.levels.first(where: { $0.id == id }) else {
            loadLevel(id: 1); return
        }
        currentLevelID = id
        steam = config.initialSteam
        steamCore = PASaveManager.shared.steamCore
        completedRecipes = []
        gameState = .playing

        board = PAHexGridHelper.allValidNodes()
        cardPool = config.cardPoolCodes.compactMap { PALevelData.decodeCard(from: $0) }
        hand = []
        levelRecipes = config.recipeIDs.compactMap { PALevelData.shared.recipe(id: $0) }
        drawCards(amount: config.initialHandCount)
    }

    func canPlace(card: PACard, at node: PANode) -> Bool {
        node.card == nil && gameState == .playing
    }

    @discardableResult
    func placeCard(card: PACard, at node: PANode) -> Bool {
        guard canPlace(card: card, at: node) else { return false }

        node.card = card
        hand.removeAll { $0.id == card.id }

        let neighborCards = PAHexGridHelper.neighbors(of: node, in: board).compactMap(\.card)
        let reaction = PAReactionEngine.processReaction(card: card, neighbors: neighborCards)

        steam += reaction.steamGain
        lastReactionSteam = reaction.steamGain
        node.contamination = max(0, min(3, node.contamination + reaction.contaminationDelta))

        PAudioManager.shared.play("card_place")
        if reaction.steamGain > 5 { PAudioManager.shared.play("reaction_pulse") }
        if reaction.contaminationDelta > 0 { PAudioManager.shared.play("contaminate") }

        checkRecipes()
        drawCards(amount: 1)

        if steam <= 0 { gameState = .lose }
        return true
    }

    func drawCards(amount: Int) {
        let needed = min(amount, maxHandSize - hand.count)
        guard needed > 0, !cardPool.isEmpty else { return }
        let take = min(needed, cardPool.count)
        hand.append(contentsOf: cardPool.prefix(take))
        cardPool.removeFirst(take)
    }

    func reshufflePool(costSteam: Int) -> Bool {
        guard steam >= costSteam else { return false }
        steam -= costSteam
        let combined = hand + cardPool
        hand = []
        cardPool = combined.shuffled()
        drawCards(amount: 5)
        PAudioManager.shared.play("shuffle")
        return true
    }

    func checkRecipes() {
        for recipe in levelRecipes where !completedRecipes.contains(recipe.id) {
            if PAPatternMatcher.checkPattern(recipe, on: board) {
                completedRecipes.insert(recipe.id)
                steam += 20
                steamCore += 5
                PAudioManager.shared.play("recipe_complete")
            }
        }
        let allDone = levelRecipes.allSatisfy { completedRecipes.contains($0.id) }
        if allDone && !levelRecipes.isEmpty {
            gameState = .win
            PAudioManager.shared.play("win_level")
            PASaveManager.shared.recordClear(levelID: currentLevelID, steamCore: steamCore)
        }
    }

    var allRecipesCount: Int { levelRecipes.count }
    var completedRecipesCount: Int { completedRecipes.count }
    var steamPercent: Double { Double(max(0, steam)) / 200.0 }
}
