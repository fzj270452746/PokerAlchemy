import Foundation

struct PALevelConfig: Codable {
    let id: Int
    let recipeIDs: [Int]
    let cardPoolCodes: [String]
    let initialSteam: Int
    let initialHandCount: Int
}

class PALevelData {
    static let shared = PALevelData()

    private(set) var levels: [PALevelConfig] = []
    private(set) var allRecipes: [PARecipePattern] = []

    private init() {
        loadLevels()
        buildRecipes()
    }

    private func loadLevels() {
        guard let url = Bundle.main.url(forResource: "Levels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([PALevelConfig].self, from: data) else {
            print("⚠️ Levels.json not found, using defaults")
            levels = PALevelData.defaultLevels()
            return
        }
        levels = decoded
    }

    private func buildRecipes() {
        allRecipes = [
            PARecipePattern(id: 101, name: "Fire Triangle",
                shape: [PAAxialCoord(q:0,r:0), PAAxialCoord(q:1,r:0), PAAxialCoord(q:0,r:1)],
                condition: .allSameSuit),
            PARecipePattern(id: 102, name: "Water Line",
                shape: [PAAxialCoord(q:-1,r:0), PAAxialCoord(q:0,r:0), PAAxialCoord(q:1,r:0)],
                condition: .consecutiveRanks),
            PARecipePattern(id: 201, name: "Earth Diamond",
                shape: [PAAxialCoord(q:0,r:-1), PAAxialCoord(q:-1,r:0), PAAxialCoord(q:0,r:0), PAAxialCoord(q:1,r:0), PAAxialCoord(q:0,r:1)],
                condition: .allSameRank),
            PARecipePattern(id: 202, name: "Air Cross",
                shape: [PAAxialCoord(q:0,r:0), PAAxialCoord(q:1,r:-1), PAAxialCoord(q:-1,r:1)],
                condition: .includesElement(.air)),
            PARecipePattern(id: 301, name: "Arcane Triad",
                shape: [PAAxialCoord(q:0,r:0), PAAxialCoord(q:2,r:0), PAAxialCoord(q:1,r:-1)],
                condition: .consecutiveRanks),
            PARecipePattern(id: 302, name: "Inferno Ring",
                shape: [PAAxialCoord(q:1,r:0), PAAxialCoord(q:0,r:1), PAAxialCoord(q:-1,r:1),
                        PAAxialCoord(q:-1,r:0), PAAxialCoord(q:0,r:-1), PAAxialCoord(q:1,r:-1)],
                condition: .allSameSuit)
        ]
    }

    func recipe(id: Int) -> PARecipePattern? {
        allRecipes.first { $0.id == id }
    }

    static func decodeCard(from code: String) -> PACard? {
        guard code.count >= 2 else { return nil }
        let suitChar = code.prefix(1)
        let rankStr = String(code.dropFirst())

        let suit: PASuit
        switch suitChar {
        case "S": suit = .spade
        case "H": suit = .heart
        case "D": suit = .diamond
        case "C": suit = .club
        default: return nil
        }

        let rank: PARank
        switch rankStr {
        case "A": rank = .ace
        case "J": rank = .jack
        case "Q": rank = .queen
        case "K": rank = .king
        default:
            guard let n = Int(rankStr), let r = PARank(rawValue: n) else { return nil }
            rank = r
        }
        return .poker(PAPokerCard(suit: suit, rank: rank))
    }

    private static func defaultLevels() -> [PALevelConfig] {
        [
            PALevelConfig(id: 1, recipeIDs: [101, 102],
                cardPoolCodes: ["SA","H2","D3","C4","S5","H6","D7","C8","S9","H10","DJ","CQ","SK","HA","D2","C3"],
                initialSteam: 100, initialHandCount: 5),
            PALevelConfig(id: 2, recipeIDs: [201, 202],
                cardPoolCodes: ["S2","H3","D4","C5","S6","H7","D8","C9","S10","HJ","DQ","CK","SA","H2","D3","C4","S5","H6"],
                initialSteam: 120, initialHandCount: 5),
            PALevelConfig(id: 3, recipeIDs: [301, 302],
                cardPoolCodes: ["HA","DA","CA","SA","HK","DK","CK","SK","HQ","DQ","CQ","SQ","HJ","DJ","CJ","SJ","H10","D10"],
                initialSteam: 150, initialHandCount: 5)
        ]
    }
}
