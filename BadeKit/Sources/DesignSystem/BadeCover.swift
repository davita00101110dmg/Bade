import SwiftUI

extension View {
    /// Full-screen on iOS; a sheet on macOS, where full-screen covers do not exist. Used for
    /// linear flows that should not compete with the tab bar.
    /// `onDismiss` runs once the cover has actually finished leaving, which is the only reliable
    /// moment to present something in its place — a timer is a guess, and a guess that is short
    /// asks UIKit to present into a stack it is still emptying.
    public func badeCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>, onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
            return fullScreenCover(item: item, onDismiss: onDismiss, content: content)
        #else
            return sheet(item: item, onDismiss: onDismiss, content: content)
        #endif
    }
}
