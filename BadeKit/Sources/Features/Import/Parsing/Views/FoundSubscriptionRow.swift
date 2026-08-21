import Core
import DesignSystem
import Localization
import SwiftUI

struct FoundSubscriptionRow: View {
    @Environment(\.badeTheme) private var theme

    let group: FoundGroup
    let settling: Double

    var body: some View {
        HStack(spacing: .sm) {
            Circle()
                .fill(theme.accent)
                .frame(width: .xs, height: .xs)
            Text(group.merchant)
                .font(.badeBody)
                .foregroundStyle(theme.ink)
                .lineLimit(1)
            if group.count > 1 {
                Text(.parsing.occurrences(group.count))
                    .font(.badeCaption)
                    .foregroundStyle(theme.inkMuted)
            }
            Spacer(minLength: .sm)
            Text(group.amount, format: .badeMoney(group.currency))
                .font(.badeAmount)
                .foregroundStyle(theme.ink)
        }
        .padding(.horizontal, .md)
        .padding(.vertical, .sm)
        .background(
            RoundedRectangle(cornerRadius: BadeRadius.lg, style: .continuous)
                .fill(theme.surfaceRaised))
        // Lands faint and slightly small, then firms up and settles to size as later rows push it
        // down the list — so the newest one always reads as the thing that just arrived.
        .opacity(1 - settling * ParsingMetrics.settleFade)
        .scaleEffect(1 - settling * ParsingMetrics.settleScale)
        .accessibilityElement(children: .combine)
    }
}
