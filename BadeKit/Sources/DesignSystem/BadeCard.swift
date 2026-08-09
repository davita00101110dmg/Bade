import SwiftUI

/// A raised panel on the page surface.
public struct BadeCard<Content: View>: View {
    @Environment(\.badeTheme) private var theme
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: BadeRadius.xl, style: .continuous)
                    .fill(theme.surfaceRaised)
            )
    }
}

/// A numbered instruction, as used by the export steps.
public struct BadeNumberedStep: View {
    @Environment(\.badeTheme) private var theme
    private let number: Int
    private let text: Text

    public init(_ number: Int, _ text: Text) {
        self.number = number
        self.text = text
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .sm) {
            Text(number, format: .number)
                .font(.badeCaption)
                .foregroundStyle(theme.inkMuted)
                .frame(width: BadeStepMetrics.badgeSize, height: BadeStepMetrics.badgeSize)
                .background(
                    RoundedRectangle(cornerRadius: BadeStepMetrics.cornerRadius, style: .continuous)
                        .fill(theme.surfaceSunken))
            text
                .font(.badeBody)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
