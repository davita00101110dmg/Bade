import Core
import DesignSystem
import Localization
import SwiftUI

/// One confidence tier: its label, and the rows or cards it holds in a single grouped panel.
struct ReviewSectionView: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale

    let section: ReviewSection
    let currency: String
    let send: (ReviewIntent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .xs) {
            header
                .padding(.horizontal, .xxs)

            VStack(spacing: .zero) {
                ForEach(section.items) { item in
                    if item.decision == .undecided {
                        UncertainCard(
                            item: item, currency: currency,
                            onAccept: { send(.acceptedUncertain(item.id)) },
                            onReject: { send(.rejectedUncertain(item.id)) })
                    } else {
                        ReviewRow(
                            item: item, currency: currency,
                            onToggle: { send(.toggled(item.id)) })
                    }
                    if item.id != section.items.last?.id {
                        Divider().overlay(theme.border).padding(.leading, .md)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: BadeRadius.lg, style: .continuous)
                    .fill(theme.surfaceRaised)
            )
        }
    }

    /// Only the tier that needs no thought gets the accent; the rest stay quiet.
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(.review.tierCount(.badeLocalized(section.title, in: locale), section.items.count))
                .badeSectionLabel(tint: section.confidence == .confident ? theme.accent : nil)
            Spacer()
            if let hint = section.hint {
                Text(hint)
                    .font(.badeCaption)
                    .foregroundStyle(theme.inkFaint)
            }
        }
    }
}
