import Core
import DesignSystem
import Localization
import SwiftUI

/// What the statement says about the conversion behind a charge, and nothing it does not.
///
/// §5.7 also wants the markup in money and annualised. That is deliberately not here yet: on a
/// real BOG statement the charge is recorded in lari with a USD-GEL conversion beside it, and
/// which side of that conversion the merchant priced in is not something the record settles. A
/// sticker price divided out of the total would be a number the statement never contained, and
/// the money figure resting on it would inherit whichever way round the guess fell.
///
/// The gap between the two printed rates is a fact, so that is what is shown.
struct ExchangeCard: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale

    let markup: FXMarkup?
    let isPaidWithoutConversion: Bool
    let currency: String

    @State private var isShowingRates = false

    var body: some View {
        BadeCard {
            VStack(alignment: .leading, spacing: .md) {
                Text(.detail.fxTitle).badeSectionLabel()

                if let markup {
                    sentence(markup)
                    rates(markup)
                } else {
                    Text(explanation)
                        .font(.badeBody)
                        .foregroundStyle(theme.inkMuted)
                }
            }
        }
    }

    /// The finding, in a sentence. Two four-decimal rates and a bare percentage are the working-out,
    /// and almost nobody reading this knows what a card scheme is; the sentence is what the section
    /// is actually for, and the numbers behind it are for whoever wants to check them.
    @ViewBuilder
    private func sentence(_ markup: FXMarkup) -> some View {
        if let gap = markup.fraction {
            Text(wording(gap, reference: markup.reference))
                .font(.badeBody)
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func wording(_ gap: Decimal, reference: FXMarkup.Reference) -> LocalizedStringResource {
        let size = abs(gap).formatted(.percent.precision(.fractionLength(2)).locale(locale))
        switch (reference, gap > 0) {
        case (.cardScheme, true): return .detail.fxCostMoreScheme(size)
        case (.cardScheme, false): return .detail.fxCostLessScheme(size)
        case (.official, true): return .detail.fxCostMoreOfficial(size)
        case (.official, false): return .detail.fxCostLessOfficial(size)
        }
    }

    /// Folded away by default and remembered by nobody: opening it is a one-off curiosity, not a
    /// preference worth storing.
    private func rates(_ markup: FXMarkup) -> some View {
        DisclosureGroup(isExpanded: $isShowingRates) {
            breakdown(markup)
        } label: {
            Text(.detail.fxShowRates)
                .font(.badeCaption)
                .foregroundStyle(theme.inkMuted)
        }
        .tint(theme.accent)
        .badeAnimation(.badeContent, value: isShowingRates)
    }

    /// Nothing converted is good news and says so; a missing rate is a gap and says that instead.
    private var explanation: LocalizedStringResource {
        isPaidWithoutConversion ? .detail.fxNoConversion(currency) : .detail.fxNoRate
    }

    private func breakdown(_ markup: FXMarkup) -> some View {
        VStack(spacing: .zero) {
            line(.detail.fxPaid) {
                Text(markup.paid, format: .badeMoney(markup.paidCurrency))
                    .font(.badeAmount)
                    .foregroundStyle(theme.ink)
            }
            divider
            line(.detail.fxBankRate) { rate(markup.bankRate) }
            divider
            line(reference(markup.reference)) { rate(markup.referenceRate) }
        }
    }

    private func reference(_ reference: FXMarkup.Reference) -> LocalizedStringResource {
        reference == .cardScheme ? .detail.fxSchemeRate : .detail.fxOfficialRate
    }

    /// A rate is not money — it has no symbol and wants more decimals than money does.
    private func rate(_ value: Decimal) -> some View {
        Text(verbatim: value.formatted(.number.precision(.fractionLength(4)).locale(locale)))
            .font(.badeAmount)
            .foregroundStyle(theme.ink)
    }

    private func line(_ label: LocalizedStringResource, @ViewBuilder value: () -> some View)
        -> some View
    {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.badeBody)
                .foregroundStyle(theme.inkMuted)
            Spacer(minLength: .sm)
            value()
        }
        .padding(.vertical, .sm)
        .accessibilityElement(children: .combine)
    }

    private var divider: some View { Divider().overlay(theme.border) }
}

extension FXMarkup {
    /// Both rates as the statement quotes them, recovered from the amounts they produced.
    fileprivate var bankRate: Decimal { charged > 0 ? paid / charged : 0 }
    fileprivate var referenceRate: Decimal { charged > 0 ? fair / charged : 0 }
}
