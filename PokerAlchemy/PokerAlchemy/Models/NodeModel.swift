import Foundation
import Combine

class PANode: ObservableObject, Identifiable {
    let id = UUID()
    let axialQ: Int
    let axialR: Int

    @Published var card: PACard?
    @Published var contamination: Int = 0

    init(q: Int, r: Int) {
        self.axialQ = q
        self.axialR = r
    }

    var axialS: Int { -axialQ - axialR }

    static func isValid(q: Int, r: Int) -> Bool {
        let s = -q - r
        return abs(q) + abs(r) + abs(s) <= 6
    }
}
