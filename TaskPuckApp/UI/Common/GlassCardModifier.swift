import SwiftUI

/// 液态玻璃 (Liquid Glass / Glassmorphism) 效果修饰器
public struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double

    public init(cornerRadius: CGFloat = 24, opacity: Double = 0.6) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(opacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.6),
                                .white.opacity(0.1),
                                .black.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
    }
}

extension View {
    public func liquidGlassCard(cornerRadius: CGFloat = 24, opacity: Double = 0.6) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
}