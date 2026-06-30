import Foundation

struct PARecipePattern: Codable {
    let id: Int
    let name: String
    let shape: [PAAxialCoord]
    let condition: PAPatternCondition
}

struct PAAxialCoord: Codable, Equatable, Hashable {
    let q: Int
    let r: Int
}

enum PAPatternCondition: Codable {
    case allSameSuit
    case consecutiveRanks
    case allSameRank
    case includesElement(PAElement)

    enum CodingKeys: String, CodingKey { case type, element }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type_ = try c.decode(String.self, forKey: .type)
        switch type_ {
        case "allSameSuit": self = .allSameSuit
        case "consecutiveRanks": self = .consecutiveRanks
        case "allSameRank": self = .allSameRank
        case "includesElement":
            let el = try c.decode(PAElement.self, forKey: .element)
            self = .includesElement(el)
        default: self = .allSameSuit
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .allSameSuit: try c.encode("allSameSuit", forKey: .type)
        case .consecutiveRanks: try c.encode("consecutiveRanks", forKey: .type)
        case .allSameRank: try c.encode("allSameRank", forKey: .type)
        case .includesElement(let el):
            try c.encode("includesElement", forKey: .type)
            try c.encode(el, forKey: .element)
        }
    }
}

enum PAGameState: Equatable {
    case playing, win, lose
}
