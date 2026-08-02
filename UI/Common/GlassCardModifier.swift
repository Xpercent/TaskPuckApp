import SwiftUI

/// 液态玻璃 (Liquid Glass / Glassmorphism) 视觉效果修饰器
public struct LiquidGlassCardModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var borderColor: Color

    public init(cornerRadius: CGFloat = 20, borderColor: Color = Color.white.opacity(0.3)) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
    }

    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

extension View {
    /// 一键应用液态毛玻璃卡片样式
    public func liquidGlassCard(cornerRadius: CGFloat = 20, borderColor: Color = Color.white.opacity(0.3)) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, borderColor: borderColor))
    }
}