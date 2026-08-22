import Core
import DesignSystem
import Localization
import SwiftUI

/// The pitch, and the one purchase Bade has. The price is never written here — it arrives from the
/// store already formatted for wherever the buyer is.
public struct ProView: View {
    @Environment(\.badeTheme) private var theme

    @State private var model: ProViewModel

    public init(model: ProViewModel = ProViewModel()) {
        _model = State(initialValue: model)
    }

    private struct Feature: Identifiable {
        let symbol: String
        let title: LocalizedStringResource
        /// What it does, for somebody deciding whether to buy.
        let detail: LocalizedStringResource
        /// Where to find it, for somebody who already has. Only Upcoming is a place the app can
        /// take you — iOS offers no way to open the widget gallery, the FX breakdown lives inside
        /// whichever subscription the bank converted, and reminders and export are two taps back
        /// in Settings. A row that looks tappable and is not reads as a bug, so the rest say where
        /// to look instead of pretending.
        let whereItLives: LocalizedStringResource?
        var id: String { symbol }
    }

    /// Only what the app does today. Price alerts, trends, category analytics and themes were
    /// listed here before any of them existed, which is both a promise Bade could not keep and a
    /// 2.3.1 rejection waiting to happen. Their strings are kept for when they ship.
    private static let features: [Feature] = [
        Feature(
            symbol: "calendar", title: .pro.calendar, detail: .pro.calendarDetail,
            whereItLives: nil),
        Feature(
            symbol: "calendar.badge.clock", title: .pro.reminders, detail: .pro.remindersDetail,
            whereItLives: .pro.remindersWhere),
        Feature(
            symbol: "square.grid.2x2", title: .pro.widgets, detail: .pro.widgetsDetail,
            whereItLives: .pro.widgetsWhere),
        Feature(
            symbol: "arrow.left.arrow.right", title: .pro.fx, detail: .pro.fxDetail,
            whereItLives: .pro.fxWhere),
        Feature(
            symbol: "square.and.arrow.up", title: .pro.export, detail: .pro.exportDetail,
            whereItLives: .pro.exportWhere),
    ]

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .xxl) {
                hero
                features
                unlock
            }
            .padding(.bottom, .xxxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
        .navigationTitle(Text(.pro.title))
        .toolbarTitleDisplayMode(.inline)
        .badeAnimation(.badeContent, value: model.state)
        .badeFeedback(.success, trigger: model.state.isEntitled)
        .onAppear { model.send(.appeared) }
    }

    /// The net is the app's one piece of ornament and it already carries the arrival moment on
    /// Welcome; the pitch earns it too. The logo drops in above the tagline when it is ready.
    private var hero: some View {
        NetPanel {
            // A page that keeps arguing after the sale is a page an owner has to scroll past to
            // reach their own receipt. Bought, the pitch becomes the confirmation.
            VStack(spacing: .sm) {
                Text(model.state.isEntitled ? .pro.owned : .pro.tagline)
                    .font(.badeDisplay)
                    .foregroundStyle(theme.ink)
                Text(model.state.isEntitled ? .pro.ownedDetail : .pro.blurb)
                    .font(.badeBody)
                    .foregroundStyle(theme.inkMuted)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, .xl)
            .padding(.vertical, .xxl)
        }
        // The panel hugs its content and the column around it aligns leading, so without this the
        // net and the tagline sat against the left edge while reading as centred text.
        .frame(maxWidth: .infinity)
    }

    /// The same five, read two ways. Unbought they argue for themselves; bought they are an
    /// inventory, and the second line stops describing the feature and starts saying where it is.
    private var features: some View {
        VStack(alignment: .leading, spacing: .lg) {
            Text(model.state.isEntitled ? .pro.ownedTitle : .pro.included).badeSectionLabel()

            ForEach(Self.features) { feature in
                if model.state.isEntitled, feature.symbol == "calendar" {
                    Button { model.send(.upcomingTapped) } label: { row(feature) }
                        .buttonStyle(.plain)
                } else {
                    row(feature)
                }
            }
        }
        .padding(.horizontal, .screenMargin)
    }

    private func row(_ feature: Feature) -> some View {
        HStack(alignment: .top, spacing: .md) {
            // Decorative. Combined with the text beside it, VoiceOver read the symbol's
            // own name out first — "bell badge, Renewal reminders".
            Image(systemName: model.state.isEntitled ? "checkmark" : feature.symbol)
                .font(.badeHeadline)
                .foregroundStyle(theme.accent)
                .frame(width: BadeSpacing.xl)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: .xxs) {
                Text(feature.title)
                    .font(.badeHeadline)
                    .foregroundStyle(theme.ink)
                Text(second(feature))
                    .font(.badeCaption)
                    .foregroundStyle(theme.inkMuted)
            }

            if model.state.isEntitled, feature.symbol == "calendar" {
                Spacer(minLength: .xs)
                Image(systemName: "chevron.right")
                    .font(.badeCaption)
                    .foregroundStyle(theme.inkFaint)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    private func second(_ feature: Feature) -> LocalizedStringResource {
        guard model.state.isEntitled else { return feature.detail }
        return feature.whereItLives ?? feature.detail
    }

    /// Buyable or unreachable — never a button that cannot say what it costs, and nothing at all
    /// once it is owned, because the hero has already said so and there is nothing left to do.
    @ViewBuilder
    private var unlock: some View {
        if !model.state.isEntitled { purchase }
    }

    private var purchase: some View {
        VStack(spacing: .xs) {
            Button { model.send(.buyTapped) } label: {
                if let price = model.state.price {
                    Text(.pro.unlockPrice(price))
                } else {
                    Text(.pro.unlock)
                }
            }
            .buttonStyle(.badePrimary)
            .disabled(model.state.isWorking || model.state.price == nil)

            Button { model.send(.restoreTapped) } label: { Text(.pro.restore) }
                .buttonStyle(.badeSecondary)
                .disabled(model.state.isWorking)

            if let note {
                Text(note)
                    .font(.badeCaption)
                    .foregroundStyle(theme.warning)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, .screenMargin)
    }

    /// One line at a time, and only when there is something the buyer has to know.
    private var note: LocalizedStringResource? {
        if model.state.hasFailed { return .pro.failed }
        if model.state.foundNothingToRestore { return .pro.nothingToRestore }
        if model.state.isStoreUnavailable { return .pro.storeUnavailable }
        return nil
    }
}
