import SwiftUI

struct PASettingsView: View {
    @State private var isMuted = PASaveManager.shared.isMuted
    @State private var showResetConfirm = false
    @State private var showHelp = false

    var body: some View {
        ZStack {
            PATheme.gradientBg.ignoresSafeArea()
            VStack(spacing: 0) {
                pageHeader
                ScrollView {
                    VStack(spacing: 14) {
                        // Sound
                        PASurface {
                            HStack {
                                Label("Sound Effects", systemImage: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(PATheme.textPrimary)
                                Spacer()
                                Toggle("", isOn: Binding(get: { !isMuted }, set: { val in
                                    isMuted = !val
                                    PASaveManager.shared.isMuted = isMuted
                                    PAudioManager.shared.setMuted(isMuted)
                                }))
                                .tint(PATheme.accentTeal)
                            }
                            .padding(16)
                        }

                        // Help
                        Button {
                            showHelp = true
                        } label: {
                            PASurface {
                                HStack {
                                    Label("How to Play", systemImage: "questionmark.circle.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(PATheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(PATheme.textSecondary)
                                }
                                .padding(16)
                            }
                        }

                        // Reset
                        Button {
                            showResetConfirm = true
                        } label: {
                            PASurface {
                                HStack {
                                    Label("Reset All Progress", systemImage: "arrow.counterclockwise")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(PATheme.danger)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(PATheme.textSecondary)
                                }
                                .padding(16)
                            }
                        }

                        // Version
                        Text("Poker Alchemy  v1.0")
                            .font(.system(size: 12)).foregroundStyle(Color(white: 0.3))
                            .padding(.top, 8)
                    }
                    .padding(16)
                }
            }

            if showResetConfirm {
                PAAlertView(
                    title: "Reset Progress",
                    message: "All level progress and Steam Cores will be permanently deleted.",
                    buttons: [
                        ("Reset", {
                            showResetConfirm = false
                            PASaveManager.shared.resetAll()
                        }),
                        ("Cancel", { showResetConfirm = false })
                    ]
                )
            }

            if showHelp {
                PAHelpSheet { showHelp = false }
            }
        }
    }

    private var pageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SETTINGS").font(.system(size: 11, weight: .bold)).foregroundStyle(PATheme.accentTeal)
                Text("Options").font(.system(size: 22, weight: .heavy)).foregroundStyle(PATheme.textPrimary)
            }
            Spacer()
            Image(systemName: "gearshape.fill").font(.system(size: 28)).foregroundStyle(PATheme.accent)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(PATheme.surface)
    }
}

struct PAHelpSheet: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 0) {
                ZStack {
                    PATheme.gradientGold
                    Text("How to Play").font(.system(size: 20, weight: .heavy)).foregroundStyle(.black)
                }
                .frame(height: 54)
                .clipShape(PARoundedCorners(corners: [.topLeft, .topRight], radius: 20))

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        helpItem(icon: "square.grid.3x3", title: "Board",
                            body: "A hex grid with 37 cells. Drag cards from your hand to empty cells.")
                        helpItem(icon: "hand.draw.fill", title: "Placement",
                            body: "Drag a card onto any empty hex cell to place it. Reactions trigger automatically.")
                        helpItem(icon: "atom", title: "Reactions",
                            body: "Placing cards near others generates Steam based on affinity (rank proximity + same suit bonus).")
                        helpItem(icon: "book.closed.fill", title: "Recipes",
                            body: "Fulfill all recipe patterns on the board to win the level. Check the Codex tab for details.")
                        helpItem(icon: "sparkles", title: "Steam Cores",
                            body: "Earned by completing recipes. Spend them in the Workshop to forge powerful upgrades.")
                        helpItem(icon: "exclamationmark.triangle.fill", title: "Contamination",
                            body: "Low-affinity placements increase contamination. High contamination reduces Steam gain.")
                    }
                    .padding(20)
                }
                .background(PATheme.surface)

                Button(action: onClose) {
                    Text("Got it")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(PATheme.gradientGold)
                }
                .clipShape(PARoundedCorners(corners: [.bottomLeft, .bottomRight], radius: 20))
            }
            .frame(width: 320, height: 480)
            .shadow(color: PATheme.accentTeal.opacity(0.3), radius: 30)
        }
    }

    private func helpItem(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(PATheme.accentTeal).frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(PATheme.textPrimary)
                Text(body).font(.system(size: 13)).foregroundStyle(PATheme.textSecondary)
            }
        }
    }
}
