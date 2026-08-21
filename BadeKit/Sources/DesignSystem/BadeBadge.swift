import SwiftUI

/// A small pill carrying one word — BETA, PRO. Its own view rather than a section label because a
/// section label's letter tracking hangs off the final character, which quietly pushes whatever it
/// sits beside off centre.
public struct BadeBadge: View {
    @Environment(\.badeTheme) private var theme

    private let text: LocalizedStringResource
    private let tint: Color?

    public init(_ text: LocalizedStringResource, tint: Color? = nil) {
        self.text = text
        self.tint = tint
    }

    public var body: some View {
        Text(text)
            .font(.badeLabel)
            .textCase(.uppercase)
            .foregroundStyle(tint ?? theme.accent)
            .padding(.horizontal, BadeBadgeMetrics.horizontalPadding)
            .padding(.vertical, BadeBadgeMetrics.verticalPadding)
            .background(
                Capsule().fill((tint ?? theme.accent).opacity(BadeBadgeMetrics.fillOpacity))
            )
            .fixedSize()
    }
}

/// The badge's own dimensions, which are its business and not the spacing scale's.
public enum BadeBadgeMetrics {
    public static let horizontalPadding = BadeSpacing.xs
    public static let verticalPadding = BadeSpacing.xxs
    public static let fillOpacity = 0.18
}
