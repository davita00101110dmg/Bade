import Core
import DesignSystem
import Localization
import SwiftUI

/// A detection the engine will not vouch for. It asks rather than assumes, and answering it
/// turns it into an ordinary row.
struct UncertainCard: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale

    let item: ReviewItem
    let currency: String
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            ReviewRowLabel(item: item, currency: currency, locale: locale)

            HStack(spacing: .xs) {
                ReviewChoiceButton(title: Text(.review.isSubscription), isProminent: true,
                    action: onAccept)
                ReviewChoiceButton(title: Text(.review.notOne), isProminent: false,
                    action: onReject)
            }
        }
        .padding(.md)
    }
}

/// One half of the answer. Neither is destructive, so neither shouts.
struct ReviewChoiceButton: View {
    @Environment(\.badeTheme) private var theme

    let title: Text
    let isProminent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            title
                .font(.badeHeadline)
                .foregroundStyle(isProminent ? theme.ink : theme.inkMuted)
                .frame(maxWidth: .infinity)
                .frame(height: ReviewChoiceMetrics.height)
                .background(
                    RoundedRectangle(
                        cornerRadius: ReviewChoiceMetrics.cornerRadius, style: .continuous
                    )
                    .fill(theme.surfaceSunken)
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
