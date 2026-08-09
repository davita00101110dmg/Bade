import Core
import DesignSystem
import Localization
import SwiftUI

/// A detection the user ticks or unticks. Uncertain items reach this shape once answered.
struct ReviewRow: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale

    let item: ReviewItem
    let currency: String
    let onToggle: () -> Void

    private var isIncluded: Bool { item.decision == .included }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: .sm) {
                ReviewCheckbox(isOn: isIncluded)
                ReviewRowLabel(item: item, currency: currency, locale: locale)
            }
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
            .frame(minHeight: BadeLayout.minimumTapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .badeAnimation(.badeSelection, value: isIncluded)
        .accessibilityAddTraits(isIncluded ? [.isButton, .isSelected] : .isButton)
    }
}

/// Merchant and cadence on the left, what actually left the account on the right.
struct ReviewRowLabel: View {
    @Environment(\.badeTheme) private var theme

    let item: ReviewItem
    let currency: String
    let locale: Locale

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .sm) {
            VStack(alignment: .leading, spacing: .xxs) {
                Text(item.subscription.merchant)
                    .font(.badeBody)
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                Text(item.caption(in: locale))
                    .font(.badeCaption)
                    .foregroundStyle(theme.inkMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: .xs)

            VStack(alignment: .trailing, spacing: .xxs) {
                Text(item.displayAmount(in: currency), format: .badeMoney(item.displayCurrency(currency)))
                    .font(.badeAmount)
                    .foregroundStyle(theme.ink)
                if let original = item.originalAmount(displayedIn: currency) {
                    Text(original, format: .badeMoney(item.subscription.currency))
                        .font(.badeCaption)
                        .foregroundStyle(theme.inkMuted)
                }
            }
        }
    }
}

/// A ticked box is the accent's only job in this list, so selection reads at a glance.
struct ReviewCheckbox: View {
    @Environment(\.badeTheme) private var theme

    let isOn: Bool

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: ReviewCheckboxMetrics.cornerRadius, style: .continuous)
    }

    var body: some View {
        shape
            .strokeBorder(
                isOn ? theme.accent : theme.border, lineWidth: ReviewCheckboxMetrics.border
            )
            .background(shape.fill(isOn ? theme.accent : .clear))
            .frame(width: ReviewCheckboxMetrics.size, height: ReviewCheckboxMetrics.size)
            .overlay {
                Image(systemName: "checkmark")
                    .font(.badeLabel)
                    .foregroundStyle(theme.surface)
                    .opacity(isOn ? 1 : 0)
            }
    }
}
