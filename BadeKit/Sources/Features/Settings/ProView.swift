import DesignSystem
import Localization
import SwiftUI

/// The pitch, and nothing that pretends to take money yet. StoreKit arrives with build step 13;
/// until then the button is visibly inert rather than quietly broken.
public struct ProView: View {
    @Environment(\.badeTheme) private var theme

    public init() {}

    private struct Feature: Identifiable {
        let symbol: String
        let title: LocalizedStringResource
        let detail: LocalizedStringResource
        var id: String { symbol }
    }

    private static let features: [Feature] = [
        Feature(symbol: "arrow.left.arrow.right", title: .pro.fx, detail: .pro.fxDetail),
        Feature(symbol: "calendar.badge.clock", title: .pro.reminders, detail: .pro.remindersDetail),
        Feature(symbol: "bell.badge", title: .pro.alerts, detail: .pro.alertsDetail),
        Feature(symbol: "chart.line.uptrend.xyaxis", title: .pro.trends, detail: .pro.trendsDetail),
        Feature(symbol: "chart.pie", title: .pro.categories, detail: .pro.categoriesDetail),
        Feature(symbol: "square.grid.2x2", title: .pro.widgets, detail: .pro.widgetsDetail),
        Feature(symbol: "paintpalette", title: .pro.themes, detail: .pro.themesDetail),
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

    private var unlock: some View {
        VStack(spacing: .sm) {
            Button {} label: { Text(.pro.unlock) }
                .buttonStyle(.badePrimary)
                .disabled(true)

            Text(.pro.comingSoon)
                .font(.badeCaption)
                .foregroundStyle(theme.inkFaint)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, .screenMargin)
    }
}
