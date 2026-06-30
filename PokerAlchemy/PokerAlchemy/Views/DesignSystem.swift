import SwiftUI
import UIKit

struct PARoundedCorners: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

// MARK: - Design Tokens
enum PATheme {
    static let bg = Color(red: 0.05, green: 0.07, blue: 0.12)
    static let surface = Color(red: 0.10, green: 0.14, blue: 0.22)
    static let surfaceHigh = Color(red: 0.14, green: 0.20, blue: 0.30)
    static let accent = Color(red: 0.85, green: 0.65, blue: 0.15)       // gold
    static let accentTeal = Color(red: 0.15, green: 0.85, blue: 0.85)   // cyan
    static let danger = Color(red: 0.9, green: 0.25, blue: 0.15)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)

    static let gradientBg = LinearGradient(
        colors: [Color(red: 0.04, green: 0.06, blue: 0.14), Color(red: 0.08, green: 0.04, blue: 0.16)],
        startPoint: .top, endPoint: .bottom
    )

    static let gradientGold = LinearGradient(
        colors: [Color(red: 0.95, green: 0.80, blue: 0.30), Color(red: 0.75, green: 0.50, blue: 0.10)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Reusable Button
struct PAGoldButton: View {
    let title: String
    let action: () -> Void
    var disabled = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(disabled ? Color(white: 0.5) : Color(red: 0.1, green: 0.08, blue: 0.04))
                .padding(.horizontal, 28).padding(.vertical, 12)
                .background(
                    disabled ? AnyView(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.25))) :
                    AnyView(RoundedRectangle(cornerRadius: 12).fill(PATheme.gradientGold))
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(PATheme.accent.opacity(0.6), lineWidth: 1))
        }
        .disabled(disabled)
    }
}

// MARK: - Panel
struct PASurface<Content: View>: View {
    let content: Content
    init(@ViewBuilder _ content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(PATheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(PATheme.accentTeal.opacity(0.25), lineWidth: 1))
            )
    }
}

// MARK: - Custom Alert
struct PAAlertView: View {
    let title: String
    let message: String
    let buttons: [(label: String, action: () -> Void)]

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                ZStack {
                    PATheme.gradientGold
                    Text(title)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.08, green: 0.06, blue: 0.02))
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                }
                .frame(height: 60)
                .clipShape(PARoundedCorners(corners: [.topLeft, .topRight], radius: 20))

                // Body
                VStack(spacing: 16) {
                    Text(message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(PATheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    HStack(spacing: 12) {
                        ForEach(Array(buttons.enumerated()), id: \.offset) { _, btn in
                            PAGoldButton(title: btn.label, action: btn.action)
                        }
                    }
                }
                .padding(24)
                .background(PATheme.surface)
                .clipShape(PARoundedCorners(corners: [.bottomLeft, .bottomRight], radius: 20))
            }
            .frame(width: 300)
            .shadow(color: PATheme.accentTeal.opacity(0.4), radius: 24)
        }
    }
}

// MARK: - Tab Label
struct PATabLabel: View {
    let icon: String
    let title: String
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 20))
            Text(title).font(.system(size: 10, weight: .semibold))
        }
    }
}
