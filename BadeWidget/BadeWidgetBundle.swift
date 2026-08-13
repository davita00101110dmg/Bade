import SwiftUI
import Widgets
import WidgetKit

/// The whole extension. Everything real — the timeline, the snapshot, the views — lives in BadeKit's
/// `Widgets` module, where it can be built and previewed without an extension around it.
@main
struct BadeWidgetBundle: WidgetBundle {
    var body: some Widget {
        Widgets.BadeWidget()
    }
}
