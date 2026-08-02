import SwiftUI

public struct FloatingTabBar: View {
    @Binding public var selectedTab: Int
    public var onPlusTapped: () -> Void

    public var body: some View {
        HStack(spacing: 16) {
            // 主导航胶囊栏
            HStack(spacing: 0) {
                // Home Tab
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(selectedTab == 0 ? Color(red: 0.2, green: 0.2, blue: 0.25) : Color.gray.opacity(0.5))
                        .frame(width: 64, height: 42)
                        .background(
                            selectedTab == 0 ? Color.black.opacity(0.06) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                        )
                }

                Spacer()

                // List Tab
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Image(systemName: "list.bullet.indent")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(selectedTab == 1 ? Color(red: 0.2, green: 0.2, blue: 0.25) : Color.gray.opacity(0.5))
                        .frame(width: 56, height: 42)
                }

                Spacer()

                // Gear Tab
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(selectedTab == 2 ? Color(red: 0.2, green: 0.2, blue: 0.25) : Color.gray.opacity(0.5))
                        .frame(width: 56, height: 42)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 58)
            .background(.regularMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)

            // 右侧悬浮圆形 "+" 按钮
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onPlusTapped()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                    .frame(width: 58, height: 58)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}