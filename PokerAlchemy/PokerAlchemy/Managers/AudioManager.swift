import Foundation
import AVFoundation
import UIKit

class PAudioManager {
    static let shared = PAudioManager()
    private var players: [String: AVAudioPlayer] = [:]
    var isMuted = false

    private init() {}

    func play(_ name: String) {
        guard !isMuted else { return }
        if let player = players[name] {
            player.currentTime = 0
            player.play()
            return
        }
        let exts = ["wav", "caf", "mp3"]
        for ext in exts {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                player.play()
                players[name] = player
                return
            }
        }
        print("⚠️ Audio not found: \(name)")
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        if muted { players.values.forEach { $0.stop() } }
    }
}
