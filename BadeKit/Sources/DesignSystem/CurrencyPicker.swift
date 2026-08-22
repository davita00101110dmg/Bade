import Foundation
import Localization
import SwiftUI

/// Two screens present this, and they are asking different questions.
///
/// The subscription form asks what a charge is billed in, which can be any currency there is — so
/// it gets every ISO code with the ones already charged lifted to the top. No shortlist there: a
/// hardcoded set of codes is a launch-market assumption, and the search field makes 300 rows fine.
///
/// Settings asks what to total in, which is a much smaller question. A rate book holds observed
/// pairs and bridges nothing, so all but a handful of those 300 would convert nothing and show a
/// zero. It gets `only`, and the caller works out what belongs in it.
///
/// Lives here rather than in a feature because neither of those two may import the other.
public struct CurrencyPicker: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss

    private let sections: [(title: LocalizedStringResource?, codes: [String])]
    private let isSearchable: Bool
    private let selected: String
    private let onPick: (String) -> Void

    /// Every currency there is, with `known` first. For naming what something is billed in.
    public init(known: [String], selected: String, onPick: @escaping (String) -> Void) {
        sections = [(.currency.known, known), (.currency.all, Self.all)]
        isSearchable = true
        self.selected = selected
        self.onPick = onPick
    }

    /// These and nothing else. For choosing what to be shown a total in.
    public init(only codes: [String], selected: String, onPick: @escaping (String) -> Void) {
        // One unheaded section: with a handful of rows a heading labels the obvious, and a search
        // field over four currencies is furniture.
        sections = [(nil, codes)]
        isSearchable = false
        self.selected = selected
        self.onPick = onPick
    }

    /// View-local: what has been typed into a search field is not the app's state.
    @State private var query = ""

    public var body: some View {
        List {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, group in
                section(group.title, codes: matching(group.codes))
            }
        }
        .badeGroupedList()
        .scrollContentBackground(.hidden)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
        .badeSearchable(isSearchable, text: $query)
        .navigationTitle(Text(.currency.title))
        .toolbarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringResource?, codes: [String]) -> some View {
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
                    .badeListRow()
                    .listRowBackground(theme.surfaceRaised)
                }
            } header: {
                if let title { Text(title).badeSectionLabel() }
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

/// `SearchFieldPlacement` has no "not at all", so the modifier is either applied or it is not.
///
/// Branching is safe here only because `isSearchable` is decided by which initialiser was used and
/// never changes afterwards. A branch on something that *does* change would change the view's shape
/// while it is on screen, which is what tears a navigation stack down.
private struct BadeSearchable: ViewModifier {
    let isSearchable: Bool
    @Binding var text: String

    @ViewBuilder
    func body(content: Content) -> some View {
        if isSearchable {
            content.searchable(text: $text, prompt: Text(.currency.search))
        } else {
            content
        }
    }
}

extension View {
    fileprivate func badeSearchable(_ isSearchable: Bool, text: Binding<String>) -> some View {
        modifier(BadeSearchable(isSearchable: isSearchable, text: text))
    }
}
