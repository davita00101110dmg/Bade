import Core
import DesignSystem
import Localization
import SwiftUI

struct UpcomingChargeRow: View {
    @Environment(\.badeTheme) private var theme

    let merchant: String
    let amount: Decimal
    let currency: String
    /// A charge that happened before its subscription was cancelled. It still counts — the money
    /// left — but it is why this month's total is larger than what the list says you pay.
    let isCancelled: Bool

    var body: some View {
        HStack(spacing: .sm) {
            VStack(alignment: .leading, spacing: .xxs) {
                Text(verbatim: merchant)
                    .font(.badeBody)
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                if isCancelled {
                    Text(.upcoming.cancelled)
                        .font(.badeCaption)
                        .foregroundStyle(theme.inkFaint)
                }
            }
            Spacer(minLength: .xs)
            Text(amount, format: .badeMoney(currency))
                .font(.badeAmount)
                .foregroundStyle(theme.ink)
        }
        .opacity(isCancelled ? BadeListRowMetrics.cancelledOpacity : 1)
        .frame(minHeight: BadeLayout.minimumTapTarget)
        .accessibilityElement(children: .combine)
    }
}
