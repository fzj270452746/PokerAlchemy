import Foundation

enum PASuit: String, CaseIterable, Codable {
    case spade, heart, club, diamond

    var symbol: String {
        switch self {
        case .spade: return "♠"
        case .heart: return "♥"
        case .club: return "♣"
        case .diamond: return "♦"
        }
    }

    var isRed: Bool { self == .heart || self == .diamond }
}

enum PARank: Int, CaseIterable, Codable {
    case ace = 1, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king

    var display: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return "\(rawValue)"
        }
    }
}

enum PAElement: String, CaseIterable, Codable {
    case fire, water, earth, air

    var icon: String {
        switch self {
        case .fire: return "🔥"
        case .water: return "💧"
        case .earth: return "🌍"
        case .air: return "💨"
        }
    }

    var imageName: String { "element_\(rawValue)" }
}

enum PATransmuteTarget: String, Codable {
    case rank, suit, both
}

protocol PACardProtocol: Codable, Identifiable {
    var id: UUID { get }
}

struct PAPokerCard: PACardProtocol, Equatable {
    let id: UUID
    let suit: PASuit
    let rank: PARank

    init(suit: PASuit, rank: PARank) {
        self.id = UUID()
        self.suit = suit
        self.rank = rank
    }
}

struct PAElementCard: PACardProtocol, Equatable {
    let id: UUID
    let element: PAElement

    init(element: PAElement) {
        self.id = UUID()
        self.element = element
    }
}

struct PATransmuteCard: PACardProtocol, Equatable {
    let id: UUID
    let target: PATransmuteTarget
    let delta: Int

    init(target: PATransmuteTarget, delta: Int) {
        self.id = UUID()
        self.target = target
        self.delta = delta
    }
}

enum PACard: Identifiable, Equatable {
    case poker(PAPokerCard)
    case element(PAElementCard)
    case transmute(PATransmuteCard)

    var id: UUID {
        switch self {
        case .poker(let c): return c.id
        case .element(let c): return c.id
        case .transmute(let c): return c.id
        }
    }

    var displayLabel: String {
        switch self {
        case .poker(let c): return c.rank.display + c.suit.symbol
        case .element(let c): return c.element.icon
        case .transmute(let c):
            let sign = c.delta >= 0 ? "+" : ""
            return "⚗\(sign)\(c.delta)"
        }
    }
}
