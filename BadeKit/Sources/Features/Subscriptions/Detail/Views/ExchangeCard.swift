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

    var body: some View {
        BadeCard {
            VStack(alignment: .leading, spacing: .md) {
                Text(.detail.fxTitle).badeSectionLabel()

                if let markup {
                    breakdown(markup)
                } else {
                    Text(explanation)
                        .font(.badeBody)
                        .foregroundStyle(theme.inkMuted)
                }
            }
        }
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

            if let gap = markup.fraction {
                divider
                line(.detail.fxRateGap) {
                    Text(gap, format: .percent.precision(.fractionLength(2)))
                        .font(.badeAmount)
                        .foregroundStyle(gap > 0 ? theme.destructive : theme.positive)
                }
            }
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
