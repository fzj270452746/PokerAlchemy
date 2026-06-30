import Foundation

class PAReactionEngine {
    static func computeAffinity(card: PACard, neighbor: PACard) -> Int {
        guard case .poker(let a) = card, case .poker(let b) = neighbor else { return 0 }
        let rankDiff = abs(a.rank.rawValue - b.rank.rawValue)
        let sameSuit = a.suit == b.suit ? 5 : 0
        return max(0, 10 - rankDiff + sameSuit)
    }

    // Returns (steamGain, contaminationDelta) for placing a card at a node
    static func processReaction(card: PACard, neighbors: [PACard]) -> (steamGain: Int, contaminationDelta: Int) {
        var steam = 0
        var contamination = 0

        for neighbor in neighbors {
            let affinity = computeAffinity(card: card, neighbor: neighbor)
            steam += affinity / 3

            if case .poker(let c) = card, case .poker(let n) = neighbor {
                let heartDiamond = (c.suit == .heart && n.suit == .diamond) || (c.suit == .diamond && n.suit == .heart)
                let spadesClubs = (c.suit == .spade && n.suit == .club) || (c.suit == .club && n.suit == .spade)

                if heartDiamond { contamination -= 1 }
                if spadesClubs { steam += 3 }

                if affinity < 3 { contamination += 1 }
            }
        }

        return (steamGain: steam, contaminationDelta: max(-3, min(3, contamination)))
    }
}
