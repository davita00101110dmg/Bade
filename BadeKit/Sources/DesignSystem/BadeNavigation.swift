import SwiftUI

extension View {
    /// Grouped list styling, which is where swipe actions live. macOS has no inset-grouped style,
    /// so it takes the nearest thing.
    public func badeGroupedList() -> some View { modifier(BadeGroupedList()) }

    /// A list row at the app's density. The row keeps its own 44pt floor; this is the space around
    /// it, tighter than the system's so a list of subscriptions reads as a list rather than a stack.
    public func badeListRow() -> some View {
        listRowInsets(
            EdgeInsets(
                top: BadeListRowMetrics.verticalInset,
                leading: BadeListRowMetrics.horizontalInset,
                bottom: BadeListRowMetrics.verticalInset,
                trailing: BadeListRowMetrics.horizontalInset))
    }

    /// Back is meaningless once a step has consumed its input, but the toolbar's close action
    /// still has to be there. No-op on macOS, which has no navigation bar to hide it from.
    public func badeHidesBackButton() -> some View {
        #if os(iOS)
            return navigationBarBackButtonHidden(true)
        #else
            return self
        #endif
    }
}

/// A concrete modifier rather than a `#if` returning `some View`: an opaque type whose shape
/// depends on the platform does not survive being read from another module, and the caller is
/// told the modifier does not exist at all.
private struct BadeGroupedList: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
            content.listStyle(.insetGrouped)
        #else
            content.listStyle(.inset)
        #endif
    }
}
