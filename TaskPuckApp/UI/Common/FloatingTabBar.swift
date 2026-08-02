import SwiftUI

public struct FloatingTabBar: View {
    @Binding public var selectedTab: Int
    public var onPlusTapped: () -> Void

    // 选中状态的颜色 #f39f99
    private let activeColor = Color(red: 243/255, green: 159/255, blue: 153/255)
    
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
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private var content: some View {
        HStack(spacing: 16) {
            // 左侧 3 个 Tab 组合在一起的胶囊容器
            segmentedTabsContainer
            
            // 右侧 plus 按钮（保持原样未动）
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
        .padding(5) // 内边距，留给选中的灰色背景块空间
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
                        .fill(Color.primary.opacity(0.08)) // 模仿图片中选中的浅灰色背景
                        .matchedGeometryEffect(id: "activeTabBackground", in: activeTabNamespace)
                }

                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(
                        isSelected
                        ? activeColor // 选中时为 #f39f99
                        : Color.primary.opacity(0.85) // 未选中时为深色/黑灰色
                    )
            }
            .frame(width: 54, height: 42) // 保持合适的大小
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: tab))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // plus 按钮完全未改动
    private var plusButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onPlusTapped()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.25))
                .frame(width: 52, height: 52)
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