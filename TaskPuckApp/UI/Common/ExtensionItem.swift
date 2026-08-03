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

extension Color {
    /// 将当前 Color 变浅/变淡（用于禁用状态）
    var lighterColor: Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)

        // RGB 灰度插值计算
        let gray = r * 0.299 + g * 0.587 + b * 0.114
        return Color(
            red: gray + 0.2 * (r - gray),
            green: gray + 0.2 * (g - gray),
            blue: gray + 0.2 * (b - gray),
            opacity: Double(a)
        )
    }
}