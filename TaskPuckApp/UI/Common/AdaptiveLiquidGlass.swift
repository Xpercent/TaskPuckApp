import SwiftUI

extension View {
    /// Uses Apple's Liquid Glass renderer only where the system API exists.
    @ViewBuilder
    public func nativeLiquidGlass<S: Shape>(
        in shape: S,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                self.glassEffect(.regular.interactive(), in: shape)
            } else {
                self.glassEffect(.regular, in: shape)
            }
        } else {
            self
        }
    }
}
