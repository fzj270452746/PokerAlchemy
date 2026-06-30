import SwiftUI
import Combine

struct PAEndlessView: View {
    @StateObject private var model = PAEndlessModel()

    var body: some View {
        ZStack {
            PATheme.gradientBg.ignoresSafeArea()
            VStack(spacing: 0) {
                pageHeader
                scoreBanner
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "infinity.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(PATheme.accentTeal)
                        .shadow(color: PATheme.accentTeal.opacity(0.5), radius: 20)

                    Text("Endless Mode")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(PATheme.textPrimary)

                    Text("Place cards and survive as long as possible.\nNo recipes — pure reaction points!")
                        .font(.system(size: 14))
                        .foregroundStyle(PATheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    PAGoldButton(title: model.isRunning ? "Give Up" : "Start") {
                        if model.isRunning { model.stop() } else { model.start() }
                    }
                }
                Spacer()
            }

            if model.showGameOver {
                PAAlertView(
                    title: "Game Over",
                    message: "Score: \(model.score)\nBest: \(PASaveManager.shared.endlessHighScore)",
                    buttons: [("Play Again", { model.start() }), ("Close", { model.showGameOver = false })]
                )
            }
        }
    }

    private var pageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ENDLESS").font(.system(size: 11, weight: .bold)).foregroundStyle(PATheme.accentTeal)
                Text("Survival").font(.system(size: 22, weight: .heavy)).foregroundStyle(PATheme.textPrimary)
            }
            Spacer()
            Image(systemName: "timer").font(.system(size: 28)).foregroundStyle(PATheme.accent)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(PATheme.surface)
    }

    private var scoreBanner: some View {
        HStack(spacing: 24) {
            statItem(title: "Score", value: "\(model.score)", icon: "star.fill", color: PATheme.accent)
            Divider().frame(height: 30).background(Color(white: 0.3))
            statItem(title: "Best", value: "\(PASaveManager.shared.endlessHighScore)", icon: "trophy.fill", color: Color(red:0.95,green:0.7,blue:0.2))
            Divider().frame(height: 30).background(Color(white: 0.3))
            statItem(title: "Steam", value: "\(model.steam)", icon: "cloud.fill", color: PATheme.accentTeal)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(PATheme.surfaceHigh)
    }

    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Label(value, systemImage: icon).font(.system(size: 15, weight: .bold)).foregroundStyle(color)
            Text(title).font(.system(size: 10)).foregroundStyle(PATheme.textSecondary)
        }
    }
}

class PAEndlessModel: ObservableObject {
    @Published var score = 0
    @Published var steam = 60
    @Published var isRunning = false
    @Published var showGameOver = false
    private var timer: Timer?

    func start() {
        score = 0; steam = 60; isRunning = true; showGameOver = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.steam -= 2
            self.score += Int.random(in: 1...5)
            if self.steam <= 0 { self.stop() }
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        isRunning = false
        PASaveManager.shared.endlessHighScore = score
        showGameOver = true
    }
}
