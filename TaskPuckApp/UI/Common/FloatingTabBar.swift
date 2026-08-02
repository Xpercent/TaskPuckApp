import SwiftUI

public struct FloatingTabBar: View {
    @Binding public var selectedTab: Int
    public var onPlusTapped: () -> Void

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
            tabButton(symbol: "house.fill", tab: 0)
            tabButton(symbol: "list.bullet.indent", tab: 1)
            tabButton(symbol: "gearshape.fill", tab: 2)
            plusButton
        }
    }

    private func tabButton(symbol: String, tab: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = tab
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(
                    selectedTab == tab
                    ? Color(red: 0.2, green: 0.2, blue: 0.25)
                    : Color.gray.opacity(0.55)
                )
                .frame(width: 56, height: 42)
        }
        .buttonStyle(.plain)
        .nativeLiquidGlass(
            in: RoundedRectangle(cornerRadius: 20, style: .continuous),
            interactive: true
        )
        .accessibilityLabel(accessibilityLabel(for: tab))
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }

    private var plusButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onPlusTapped()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.25))
                .frame(width: 58, height: 58)
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