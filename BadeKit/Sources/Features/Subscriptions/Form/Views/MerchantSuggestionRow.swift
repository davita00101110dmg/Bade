import DesignSystem
import Localization
import SwiftUI

/// Catalog names offered under the field as it is typed. A row that scrolls rather than wraps, so
/// a long name never pushes the field it belongs to off its own line.
struct MerchantSuggestionRow: View {
    @Environment(\.badeTheme) private var theme

    let names: [String]
    let onPick: (String) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .xs) {
                ForEach(names, id: \.self) { name in
                    Button { onPick(name) } label: { chip(name) }.buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
        .accessibilityLabel(Text(.form.suggestions))
    }

    private func chip(_ name: String) -> some View {
        Text(verbatim: name)
            .font(.badeCaption)
            .foregroundStyle(theme.ink)
            .lineLimit(1)
            .padding(.horizontal, .sm)
            .padding(.vertical, .xs)
            .background(Capsule(style: .continuous).fill(theme.surfaceSunken))
    }
}
