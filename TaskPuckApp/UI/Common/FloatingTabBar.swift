import SwiftUI

public struct FloatingTabBar: View {
    @Binding public var selectedTab: Int
    public var onPlusTapped: () -> Void

    // 选中状态的颜色 #f39f99
    @AppStorage("app_theme_hex") private var themeHex = "EE8C8C"
    private var activeColor: Color { Color(hex: themeHex) }
    
    // 用于选中项滑动动画的命名空间
    @Namespace private var activeTabNamespace

    public init(selectedTab: Binding<Int>, onPlusTapped: @escaping () -> Void) {
        self._selectedTab = selectedTab
        self.onPlusTapped = onPlusTapped
    }

    public var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 16) {
                    content
                }
            } else {
                content
            }
        }
        .padding(.horizontal, 16) // 外层左右边距略微缩减，让栏目更饱满
        .padding(.bottom, 4)
    }

    private var content: some View {
        HStack(spacing: 12) {
            // 左侧 3 个 Tab 组合在一起的胶囊容器
            segmentedTabsContainer
            
            // 右侧 plus 按钮
            plusButton
        }
    }

    // 3 个功能 Tab 的集成容器
    private var segmentedTabsContainer: some View {
        HStack(spacing: 4) {
            tabButton(symbol: "house.fill", tab: 0)
            tabButton(symbol: "list.bullet.indent", tab: 1)
            tabButton(symbol: "gearshape.fill", tab: 2)
        }
        .padding(6) // 稍微增大内边距，匹配变大后的选中框
        .nativeLiquidGlass(
            in: Capsule(),
            interactive: true
        )
    }

    // 单个 Tab 按钮
    private func tabButton(symbol: String, tab: Int) -> some View {
        let isSelected = selectedTab == tab
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tab
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                // 选中时的浅灰色底块滑块
                if isSelected {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .matchedGeometryEffect(id: "activeTabBackground", in: activeTabNamespace)
                }

                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold)) // 图标随之变大 (19 -> 22)
                    .foregroundStyle(
                        isSelected
                        ? activeColor
                        : Color.primary.opacity(0.85)
                    )
            }
            .frame(width: 82, height: 56) // 【修改】：高度增加1/3 (42 -> 56)，宽度拉长 (54 -> 82)
            .contentShape(Capsule()) // 【关键修复】：将整个 82x56 胶囊区域设为点击热区，避免透明处按压不响应
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: tab))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // plus 按钮
    private var plusButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onPlusTapped()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .semibold)) // 图标等比例变大 (22 -> 26)
                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.25))
                .frame(width: 68, height: 68) // 【修改】：整体尺寸增大约1/3 (52x52 -> 68x68)
                .contentShape(Circle()) // 【关键修复】：整个 68x68 圆形范围全面响应触摸
        }
        .buttonStyle(.plain)
        .nativeLiquidGlass(in: Circle(), interactive: true)
    }

    private func accessibilityLabel(for tab: Int) -> String {
        switch tab {
        case 0: return "今日"
        case 1: return "任务"
        default: return "设置"
        }
    }
}
