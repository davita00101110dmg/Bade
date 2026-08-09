import Core
import DesignSystem
import Localization
import SwiftUI

struct StatementFileCard: View {
    @Environment(\.badeTheme) private var theme

    let file: StatementFile
    let monthCount: Int?
    let transactionCount: Int?

    var body: some View {
        HStack(spacing: .sm) {
            Image(systemName: "doc.text")
                .font(.badeTitle)
                .foregroundStyle(theme.inkFaint)
                .frame(width: BadeLayout.minimumTapTarget, height: BadeLayout.minimumTapTarget)
                .background(
                    RoundedRectangle(cornerRadius: BadeRadius.md, style: .continuous)
                        .fill(theme.surfaceSunken))

            VStack(alignment: .leading, spacing: .xxs) {
                Text(file.name)
                    .font(.badeHeadline)
                    .foregroundStyle(theme.ink)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(details)
                    .font(.badeCaption)
                    .foregroundStyle(theme.inkMuted)
                    .contentTransition(.numericText())
            }
            Spacer(minLength: .zero)
        }
        .padding(.sm)
        .background(
            RoundedRectangle(cornerRadius: BadeRadius.xl, style: .continuous)
                .fill(theme.surfaceRaised))
        .badeAnimation(.badeContent, value: transactionCount)
        .accessibilityElement(children: .combine)
    }

    private var details: String {
        var parts = [file.byteCount.formatted(.byteCount(style: .file))]
        if let monthCount {
            parts.append(String(localized: .parsing.months(monthCount)))
        }
        if let transactionCount {
            parts.append(String(localized: .parsing.transactions(transactionCount)))
        }
        return parts.joined(separator: " · ")
    }
}
