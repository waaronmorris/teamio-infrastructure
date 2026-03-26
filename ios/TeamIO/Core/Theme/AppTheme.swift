import SwiftUI

enum AppTheme {
    // MARK: - Colors

    static let primary = Color.accentColor
    static let secondary = Color.secondary
    static let destructive = Color.red
    static let success = Color.green
    static let warning = Color.orange

    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundGrouped = Color(.systemGroupedBackground)

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: - Corner Radius

    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16
}

// MARK: - Common View Modifiers

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.spacingMD)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
