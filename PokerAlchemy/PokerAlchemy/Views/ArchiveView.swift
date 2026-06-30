import SwiftUI

struct PAArchiveView: View {
    @State private var clearedLevels = PASaveManager.shared.clearedLevels
    private let allLevels = PALevelData.shared.levels

    var body: some View {
        ZStack {
            PATheme.gradientBg.ignoresSafeArea()
            VStack(spacing: 0) {
                pageHeader
                if clearedLevels.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(allLevels, id: \.id) { level in
                                PAArchiveRow(level: level, cleared: clearedLevels.contains(level.id))
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .onAppear { clearedLevels = PASaveManager.shared.clearedLevels }
    }

    private var pageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ARCHIVE").font(.system(size: 11, weight: .bold)).foregroundStyle(PATheme.accentTeal)
                Text("Records").font(.system(size: 22, weight: .heavy)).foregroundStyle(PATheme.textPrimary)
            }
            Spacer()
            Image(systemName: "scroll.fill").font(.system(size: 28)).foregroundStyle(PATheme.accent)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(PATheme.surface)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "hourglass").font(.system(size: 56)).foregroundStyle(Color(white: 0.35))
            Text("No records yet").font(.system(size: 18, weight: .semibold)).foregroundStyle(Color(white: 0.4))
            Text("Complete levels to see your history here.").font(.system(size: 13)).foregroundStyle(Color(white: 0.3))
            Spacer()
        }
    }
}

struct PAArchiveRow: View {
    let level: PALevelConfig
    let cleared: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(cleared ? PATheme.accent.opacity(0.2) : Color(white: 0.1))
                    .frame(width: 48, height: 48)
                if cleared {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(PATheme.accent)
                } else {
                    Text("\(level.id)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(white: 0.4))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Level \(level.id)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(cleared ? PATheme.textPrimary : Color(white: 0.45))
                Text("Recipes: \(level.recipeIDs.count)  ·  Steam: \(level.initialSteam)")
                    .font(.system(size: 12))
                    .foregroundStyle(PATheme.textSecondary)
            }
            Spacer()
            Text(cleared ? "Cleared" : "Locked")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(cleared ? Color(red:0.3,green:0.9,blue:0.4) : Color(white:0.35))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill((cleared ? Color(red:0.1,green:0.4,blue:0.15) : Color(white:0.1))))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(PATheme.surface)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(cleared ? PATheme.accent.opacity(0.35) : Color(white:0.15), lineWidth: 1))
        )
    }
}
