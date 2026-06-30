import Foundation

class PAPatternMatcher {
    static func checkPattern(_ pattern: PARecipePattern, on board: [PANode]) -> Bool {
        let nodeMap = Dictionary(uniqueKeysWithValues: board.map { (PAAxialCoord(q: $0.axialQ, r: $0.axialR), $0) })

        // Find all possible offsets by iterating each occupied node as anchor
        for anchor in board where anchor.card != nil {
            let cards = matchShape(pattern.shape, anchor: PAAxialCoord(q: anchor.axialQ, r: anchor.axialR), map: nodeMap)
            guard let cards = cards else { continue }
            if evaluateCondition(pattern.condition, cards: cards) { return true }
        }
        return false
    }

    private static func matchShape(_ shape: [PAAxialCoord], anchor: PAAxialCoord, map: [PAAxialCoord: PANode]) -> [PACard]? {
        var cards: [PACard] = []
        for coord in shape {
            let target = PAAxialCoord(q: anchor.q + coord.q, r: anchor.r + coord.r)
            guard let node = map[target], let card = node.card else { return nil }
            cards.append(card)
        }
        return cards
    }

    private static func evaluateCondition(_ condition: PAPatternCondition, cards: [PACard]) -> Bool {
        let pokerCards = cards.compactMap { if case .poker(let c) = $0 { return c } else { return nil } }

        switch condition {
        case .allSameSuit:
            guard !pokerCards.isEmpty, pokerCards.count == cards.count else { return false }
            return Set(pokerCards.map(\.suit)).count == 1

        case .allSameRank:
            guard !pokerCards.isEmpty, pokerCards.count == cards.count else { return false }
            return Set(pokerCards.map(\.rank)).count == 1

        case .consecutiveRanks:
            guard !pokerCards.isEmpty, pokerCards.count == cards.count else { return false }
            let sorted = pokerCards.map(\.rank.rawValue).sorted()
            for i in 1..<sorted.count {
                if sorted[i] != sorted[i-1] + 1 { return false }
            }
            return true

        case .includesElement(let el):
            return cards.contains { if case .element(let ec) = $0 { return ec.element == el } else { return false } }
        }
    }
}
