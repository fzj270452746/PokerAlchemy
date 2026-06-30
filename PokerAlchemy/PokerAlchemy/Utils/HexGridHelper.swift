import Foundation

struct PAHexGridHelper {
    static let directions: [(q: Int, r: Int)] = [
        (1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)
    ]

    static func allValidNodes() -> [PANode] {
        var nodes: [PANode] = []
        for q in -3...3 {
            for r in -3...3 {
                if PANode.isValid(q: q, r: r) {
                    nodes.append(PANode(q: q, r: r))
                }
            }
        }
        return nodes
    }

    static func neighbors(of node: PANode, in board: [PANode]) -> [PANode] {
        let nodeMap = Dictionary(uniqueKeysWithValues: board.map {
            (PAAxialCoord(q: $0.axialQ, r: $0.axialR), $0)
        })
        return directions.compactMap { d in
            nodeMap[PAAxialCoord(q: node.axialQ + d.q, r: node.axialR + d.r)]
        }
    }

    // Convert axial to pixel (pointy-top hexagon)
    static func axialToPixel(q: Int, r: Int, size: CGFloat) -> CGPoint {
        let x = size * (sqrt(3.0) * CGFloat(q) + sqrt(3.0) / 2.0 * CGFloat(r))
        let y = size * (3.0 / 2.0 * CGFloat(r))
        return CGPoint(x: x, y: y)
    }
}
