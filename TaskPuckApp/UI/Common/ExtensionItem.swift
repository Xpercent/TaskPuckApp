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
    /// 将颜色变浅（向白色混合）
    /// - Parameter percentage: 变浅程度，范围 0.0 ~ 1.0，默认 0.5（越接近 1 越白）
    func lighterColor(by percentage: CGFloat = 0.5) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)

        // 向 1.0 (白色) 插值计算
        let newR = r + (1.0 - r) * percentage
        let newG = g + (1.0 - g) * percentage
        let newB = b + (1.0 - b) * percentage

        return Color(
            red: Double(newR),
            green: Double(newG),
            blue: Double(newB),
            opacity: Double(a)
        )
    }
}