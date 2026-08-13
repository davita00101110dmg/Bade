import Foundation
import WidgetKit

/// The one channel between the app and its widget: a file in the group container both can see.
///
/// A widget cannot read the app's store — separate process, separate sandbox — so the app writes
/// what the home screen needs and the widget only decodes it. `directory` exists so tests can run
/// somewhere other than the real container.
public struct WidgetFeed: Sendable {
    /// Must match the App Group capability on both the app and the widget target.
    public static let appGroup = "group.com.khvedelidze.Bade"

    private static let fileName = "widget.json"

    private let directory: URL?

    public init(directory: URL? = nil) {
        self.directory =
            directory
            ?? FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: Self.appGroup)
    }

    /// Writes what the widget draws and asks WidgetKit to redraw it. Silent on failure: a home
    /// screen that is one import out of date is not worth interrupting anybody over.
    public func publish(_ snapshot: WidgetSnapshot) {
        guard let file else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: file, options: .atomic)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// The last published snapshot, or an empty one before the app has ever written it.
    public func read() -> WidgetSnapshot {
        guard let file, let data = try? Data(contentsOf: file),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }

    private var file: URL? { directory?.appending(path: Self.fileName) }
}
