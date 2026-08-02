import SwiftUI

/// 首页与任务页底部的悬浮液态玻璃导航栏（对齐图一/图二样式）
public struct FloatingTabBar: View {
    @Binding public var selectedTab: Int
    public var onPlusTapped: () -> Void

    public init(selectedTab: Binding<Int>, onPlusTapped: @escaping () -> Void) {
        self._selectedTab = selectedTab
        self.onPlusTapped = onPlusTapped
    }

    public var body: some View {
        HStack(spacing: 0) {
            // 主毛玻璃胶囊导航栏
            HStack(spacing: 32) {
                // Tab 0: 首页/时间轴 (House icon)
                Button(action: { selectedTab = 0 }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(selectedTab == 0 ? Color(red: 0.2, green: 0.2, blue: 0.25) : Color.gray.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == 0 ? Color.black.opacity(0.06) : Color.clear,
                            in: Capsule()
                        )
                }

                // Tab 1: 任务管理 (List icon)
                Button(action: { selectedTab = 1 }) {
                    Image(systemName: "list.bullet.indent")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(selectedTab == 1 ? Color(red: 0.2, green: 0.2, blue: 0.25) : Color.gray.opacity(0.6))
                }

                // Tab 2: 设置 (Gear icon)
                Button(action: { selectedTab = 2 }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(selectedTab == 2 ? Color(red: 0.2, green: 0.2, blue: 0.25) : Color.gray.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)

            Spacer()

            // 右侧悬浮圆形白色加号按钮
            Button(action: onPlusTapped) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                    .frame(width: 56, height: 56)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}