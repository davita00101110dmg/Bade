import SwiftUI

/// Filled accent, full width — the one obvious action on a screen.
public struct BadePrimaryButtonStyle: ButtonStyle {
    @Environment(\.badeTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.badeHeadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, BadeButtonMetrics.primaryVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: BadeButtonMetrics.cornerRadius, style: .continuous)
                    .fill(configuration.isPressed ? theme.accentPressed : theme.accent)
            )
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(.rect)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .badeAnimation(.badePress, value: configuration.isPressed)
    }
}

/// A plain text action sitting under the primary one — deliberately quiet.
public struct BadeSecondaryButtonStyle: ButtonStyle {
    @Environment(\.badeTheme) private var theme

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.badeHeadline)
            .foregroundStyle(configuration.isPressed ? theme.accent : theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, BadeButtonMetrics.secondaryVerticalPadding)
            .contentShape(.rect)
    }
}

extension ButtonStyle where Self == BadePrimaryButtonStyle {
    public static var badePrimary: BadePrimaryButtonStyle { BadePrimaryButtonStyle() }
}

extension ButtonStyle where Self == BadeSecondaryButtonStyle {
    public static var badeSecondary: BadeSecondaryButtonStyle { BadeSecondaryButtonStyle() }
}
