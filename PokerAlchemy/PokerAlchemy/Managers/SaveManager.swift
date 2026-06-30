import Foundation

class PASaveManager {
    static let shared = PASaveManager()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let currentLevelID = "pa_currentLevelID"
        static let steamCore = "pa_steamCore"
        static let clearedLevels = "pa_clearedLevels"
        static let isMuted = "pa_isMuted"
        static let endlessHighScore = "pa_endlessHighScore"
    }

    var currentLevelID: Int {
        get { max(1, defaults.integer(forKey: Keys.currentLevelID)) }
        set { defaults.set(newValue, forKey: Keys.currentLevelID) }
    }

    var steamCore: Int {
        get { defaults.integer(forKey: Keys.steamCore) }
        set { defaults.set(newValue, forKey: Keys.steamCore) }
    }

    var clearedLevels: [Int] {
        get { defaults.array(forKey: Keys.clearedLevels) as? [Int] ?? [] }
        set { defaults.set(newValue, forKey: Keys.clearedLevels) }
    }

    var isMuted: Bool {
        get { defaults.bool(forKey: Keys.isMuted) }
        set { defaults.set(newValue, forKey: Keys.isMuted) }
    }

    var endlessHighScore: Int {
        get { defaults.integer(forKey: Keys.endlessHighScore) }
        set { defaults.set(max(endlessHighScore, newValue), forKey: Keys.endlessHighScore) }
    }

    func recordClear(levelID: Int, steamCore: Int) {
        if !clearedLevels.contains(levelID) {
            var arr = clearedLevels
            arr.append(levelID)
            clearedLevels = arr
        }
        self.steamCore = steamCore
        if levelID >= currentLevelID {
            currentLevelID = levelID + 1
        }
    }

    func resetAll() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        defaults.removePersistentDomain(forName: domain)
    }
}
