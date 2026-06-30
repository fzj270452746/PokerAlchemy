import SwiftUI

struct PARecipeBookView: View {
    private let recipes = PALevelData.shared.allRecipes

    var body: some View {
        ZStack {
            PATheme.gradientBg.ignoresSafeArea()
            VStack(spacing: 0) {
                pageHeader
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(recipes, id: \.id) { recipe in
                            PARecipeCard(recipe: recipe)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private var pageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CODEX").font(.system(size: 11, weight: .bold)).foregroundStyle(PATheme.accentTeal)
                Text("Recipe Book").font(.system(size: 22, weight: .heavy)).foregroundStyle(PATheme.textPrimary)
            }
            Spacer()
            Image(systemName: "book.closed.fill").font(.system(size: 28)).foregroundStyle(PATheme.accent)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(PATheme.surface)
    }
}

struct PARecipeCard: View {
    let recipe: PARecipePattern

    var body: some View {
        PASurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(recipe.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(PATheme.accent)
                    Spacer()
                    conditionBadge
                }

                PAHexShapePreview(shape: recipe.shape)
                    .frame(height: 100)
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var conditionBadge: some View {
        let (text, color): (String, Color) = {
            switch recipe.condition {
            case .allSameSuit: return ("Same Suit", PATheme.accentTeal)
            case .allSameRank: return ("Same Rank", Color(red:0.6,green:0.3,blue:0.9))
            case .consecutiveRanks: return ("Sequence", PATheme.accent)
            case .includesElement(let el): return (el.rawValue.capitalized, Color(red:0.3,green:0.85,blue:0.4))
            }
        }()
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Capsule().fill(color))
    }
}

struct PAHexShapePreview: View {
    let shape: [PAAxialCoord]

    var body: some View {
        GeometryReader { geo in
            let r: CGFloat = 16
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            ForEach(Array(shape.enumerated()), id: \.offset) { _, coord in
                let px = PAHexGridHelper.axialToPixel(q: coord.q, r: coord.r, size: r)
                PAHexCell()
                    .fill(PATheme.accentTeal.opacity(0.5))
                    .overlay(PAHexCell().stroke(PATheme.accentTeal, lineWidth: 1.5))
                    .frame(width: r * 1.9, height: r * 2.1)
                    .position(x: cx + px.x, y: cy - px.y)
            }
        }
    }
}

struct PAHexCell: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 6
            let pt = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}
