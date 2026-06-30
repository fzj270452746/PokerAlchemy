import SwiftUI

struct PAForgeView: View {
    @State private var steamCore = PASaveManager.shared.steamCore
    @State private var showResult: String? = nil
    @State private var showAlert = false
    @State private var selectedOption: PAForgeOption? = nil

    let options: [PAForgeOption] = [
        PAForgeOption(name: "Steam Surge", cost: 10, description: "Start next level with +30 Steam.", icon: "flame.fill"),
        PAForgeOption(name: "Arcane Lens", cost: 15, description: "Reveal recipe hints on board.", icon: "eye.fill"),
        PAForgeOption(name: "Golden Touch", cost: 20, description: "Next card placed gives +10 Steam.", icon: "sparkles"),
        PAForgeOption(name: "Void Cleanse", cost: 12, description: "Remove all contamination.", icon: "wind"),
    ]

    var body: some View {
        ZStack {
            PATheme.gradientBg.ignoresSafeArea()
            VStack(spacing: 0) {
                pageHeader
                coreBanner
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(options) { opt in
                            PAForgeOptionRow(option: opt, available: steamCore >= opt.cost) {
                                selectedOption = opt
                                showAlert = true
                            }
                        }
                    }
                    .padding(16)
                }
            }
            if showAlert, let opt = selectedOption {
                PAAlertView(
                    title: "Forge: \(opt.name)",
                    message: "Cost: \(opt.cost) Steam Cores\n\(opt.description)",
                    buttons: [
                        ("Forge", {
                            showAlert = false
                            if PASaveManager.shared.steamCore >= opt.cost {
                                PASaveManager.shared.steamCore -= opt.cost
                                steamCore = PASaveManager.shared.steamCore
                                showResult = "\(opt.name) forged!"
                            }
                        }),
                        ("Cancel", { showAlert = false })
                    ]
                )
            }
        }
        .overlay(alignment: .top) {
            if let msg = showResult {
                Text(msg)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Capsule().fill(PATheme.accent))
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showResult = nil }
                    }
            }
        }
        .animation(.spring(), value: showResult)
    }

    private var pageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("WORKSHOP").font(.system(size: 11, weight: .bold)).foregroundStyle(PATheme.accentTeal)
                Text("Forge").font(.system(size: 22, weight: .heavy)).foregroundStyle(PATheme.textPrimary)
            }
            Spacer()
            Image(systemName: "hammer.fill").font(.system(size: 28)).foregroundStyle(PATheme.accent)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(PATheme.surface)
    }

    private var coreBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles").foregroundStyle(PATheme.accent)
            Text("Steam Cores: \(steamCore)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(PATheme.accent)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(PATheme.surfaceHigh)
    }
}

struct PAForgeOption: Identifiable {
    let id = UUID()
    let name: String
    let cost: Int
    let description: String
    let icon: String
}

struct PAForgeOptionRow: View {
    let option: PAForgeOption
    let available: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: option.icon)
                    .font(.system(size: 26))
                    .foregroundStyle(available ? PATheme.accentTeal : Color(white: 0.4))
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(available ? PATheme.textPrimary : Color(white: 0.45))
                    Text(option.description)
                        .font(.system(size: 12))
                        .foregroundStyle(PATheme.textSecondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "sparkles").font(.system(size: 11))
                    Text("\(option.cost)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(available ? PATheme.accent : Color(white: 0.4))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(available ? PATheme.accent.opacity(0.15) : Color(white: 0.1)))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(PATheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(
                        available ? PATheme.accentTeal.opacity(0.3) : Color(white: 0.15), lineWidth: 1))
            )
        }
        .disabled(!available)
    }
}
