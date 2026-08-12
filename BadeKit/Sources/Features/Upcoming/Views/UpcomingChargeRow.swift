import Core
import DesignSystem
import SwiftUI

struct UpcomingChargeRow: View {
    @Environment(\.badeTheme) private var theme

    let merchant: String
    let amount: Decimal
    let currency: String

    var body: some View {
        HStack(spacing: .sm) {
            Text(verbatim: merchant)
                .font(.badeBody)
                .foregroundStyle(theme.ink)
                .lineLimit(1)
            Spacer(minLength: .xs)
            Text(amount, format: .badeMoney(currency))
                .font(.badeAmount)
                .foregroundStyle(theme.ink)
        }
        .frame(minHeight: BadeLayout.minimumTapTarget)
        .accessibilityElement(children: .combine)
    }
}
