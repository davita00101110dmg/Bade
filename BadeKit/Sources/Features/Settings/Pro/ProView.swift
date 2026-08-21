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
        let detail: LocalizedStringResource
        var id: String { symbol }
    }

    /// Only what the app does today. Price alerts, trends, category analytics and themes were
    /// listed here before any of them existed, which is both a promise Bade could not keep and a
    /// 2.3.1 rejection waiting to happen. Their strings are kept for when they ship.
    private static let features: [Feature] = [
        Feature(symbol: "calendar", title: .pro.calendar, detail: .pro.calendarDetail),
        Feature(
            symbol: "calendar.badge.clock", title: .pro.reminders, detail: .pro.remindersDetail),
        Feature(symbol: "square.grid.2x2", title: .pro.widgets, detail: .pro.widgetsDetail),
        Feature(symbol: "arrow.left.arrow.right", title: .pro.fx, detail: .pro.fxDetail),
        Feature(symbol: "square.and.arrow.up", title: .pro.export, detail: .pro.exportDetail),
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
            VStack(spacing: .sm) {
                Text(.pro.tagline)
                    .font(.badeDisplay)
                    .foregroundStyle(theme.ink)
                Text(.pro.blurb)
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

    private var features: some View {
        VStack(alignment: .leading, spacing: .lg) {
            Text(.pro.included).badeSectionLabel()

            ForEach(Self.features) { feature in
                HStack(alignment: .top, spacing: .md) {
                    Image(systemName: feature.symbol)
                        .font(.badeHeadline)
                        .foregroundStyle(theme.accent)
                        .frame(width: BadeSpacing.xl)

                    VStack(alignment: .leading, spacing: .xxs) {
                        Text(feature.title)
                            .font(.badeHeadline)
                            .foregroundStyle(theme.ink)
                        Text(feature.detail)
                            .font(.badeCaption)
                            .foregroundStyle(theme.inkMuted)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, .screenMargin)
    }

    /// Owned, buyable, or unreachable — never a button that cannot say what it costs.
    @ViewBuilder
    private var unlock: some View {
        if model.state.isEntitled {
            owned
        } else {
            purchase
        }
    }

    private var owned: some View {
        VStack(spacing: .xxs) {
            Text(.pro.owned)
                .font(.badeHeadline)
                .foregroundStyle(theme.accent)
            Text(.pro.ownedDetail)
                .font(.badeCaption)
                .foregroundStyle(theme.inkMuted)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .screenMargin)
        .accessibilityElement(children: .combine)
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
