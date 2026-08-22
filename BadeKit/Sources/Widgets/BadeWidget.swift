import DesignSystem
import Localization
import SwiftUI
import WidgetKit

/// Declared here rather than in the extension target, so everything but `@main` is in the package
/// where it can be built, tested and previewed.
public struct BadeWidget: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BadeWidget", provider: WidgetTimeline()) { entry in
            BadeWidgetView(snapshot: entry.snapshot)
                // The app's language, not the phone's — words, weekdays and money all follow it.
                .environment(\.locale, entry.snapshot.locale)
                .containerBackground(for: .widget) { WidgetBackground() }
                .badeTheme()
        }
        .configurationDisplayName(Text(.widget.name))
        .description(Text(.widget.description))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

public struct WidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: WidgetSnapshot
}

/// There is nothing to predict: the app republishes whenever its data changes, and asks WidgetKit to
/// redraw. The daily refresh is only so a passed charge stops being "next" on its own.
public struct WidgetTimeline: TimelineProvider {
    private let feed = WidgetFeed()

    public init() {}

    public func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: .now, snapshot: .empty)
    }

    public func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(WidgetEntry(date: .now, snapshot: feed.read()))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void)
    {
        let entry = WidgetEntry(date: .now, snapshot: feed.read())
        let tomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now)
        completion(Timeline(entries: [entry], policy: .after(tomorrow)))
    }
}

/// Reads the appearance rather than the theme. WidgetKit lifts this content out and draws it as the
/// tile's background, so it is not a descendant of anything the widget's view applies — including
/// `badeTheme`. Left to inherit, it fell back to the light palette while the content resolved dark,
/// which put a near-white total on a cream tile and read as an empty widget.
private struct WidgetBackground: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        BadeTheme.matching(scheme, contrast: contrast).surface
    }
}
