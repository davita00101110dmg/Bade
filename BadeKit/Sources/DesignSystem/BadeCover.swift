import SwiftUI

extension View {
    /// Full-screen on iOS; a sheet on macOS, where full-screen covers do not exist. Used for
    /// linear flows that should not compete with the tab bar.
    public func badeCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
            return fullScreenCover(item: item, content: content)
        #else
            return sheet(item: item, content: content)
        #endif
    }
}
