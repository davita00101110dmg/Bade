import Foundation
import Localization
import SwiftUI

/// Every ISO currency, with the ones already being charged lifted to the top. No shortlist: a
/// hardcoded set of codes is a launch-market assumption, and the search field makes 300 rows fine.
///
/// Lives here rather than in a feature because two of them present it — the subscription form and
/// Settings — and neither may import the other.
public struct CurrencyPicker: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss

    private let known: [String]
    private let selected: String
    private let onPick: (String) -> Void

    public init(known: [String], selected: String, onPick: @escaping (String) -> Void) {
        self.known = known
        self.selected = selected
        self.onPick = onPick
    }

    /// View-local: what has been typed into a search field is not the app's state.
    @State private var query = ""

    public var body: some View {
        List {
            section(.currency.known, codes: matching(known))
            section(.currency.all, codes: matching(Self.all))
        }
        .badeGroupedList()
        .scrollContentBackground(.hidden)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
        .searchable(text: $query, prompt: Text(.currency.search))
        .navigationTitle(Text(.currency.title))
        .toolbarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringResource, codes: [String]) -> some View {
        if !codes.isEmpty {
            Section {
                ForEach(codes, id: \.self) { code in
                    Button {
                        onPick(code)
                        dismiss()
                    } label: {
                        row(code)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(theme.surfaceRaised)
                }
            } header: {
                Text(title).badeSectionLabel()
            }
        }
    }

    private func row(_ code: String) -> some View {
        HStack(spacing: .sm) {
            Text(verbatim: code)
                .font(.badeAmount)
                .foregroundStyle(theme.ink)
            Text(verbatim: name(of: code))
                .font(.badeBody)
                .foregroundStyle(theme.inkMuted)
                .lineLimit(1)
            Spacer(minLength: .xs)
            if code == selected {
                Image(systemName: "checkmark").foregroundStyle(theme.accent)
            }
        }
        .frame(minHeight: BadeLayout.minimumTapTarget)
        .contentShape(.rect)
    }

    private func matching(_ codes: [String]) -> [String] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return codes }
        return codes.filter {
            $0.localizedStandardContains(query) || name(of: $0).localizedStandardContains(query)
        }
    }

    private func name(of code: String) -> String {
        locale.localizedString(forCurrencyCode: code) ?? code
    }

    private static let all: [String] = Locale.Currency.isoCurrencies
        .map(\.identifier)
        .map { $0.uppercased() }
        .sorted()
}
