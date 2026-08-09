import SwiftUI

extension View {
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
