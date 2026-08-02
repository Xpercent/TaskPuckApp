import SwiftUI

public struct FloatingTabBar: View {
    @Binding public var selectedTab: Int
    public var onPlusTapped: () -> Void

    public var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 16) {
                    tabBarContent
                }
            } else {
                tabBarContent
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private var tabBarContent: some View {
        HStack(spacing: 16) {
            HStack(spacing: 0) {
                tabButton(symbol: "house.fill", tab: 0)
                Spacer()
                tabButton(symbol: "list.bullet.indent", tab: 1)
                Spacer()
                tabButton(symbol: "gearshape.fill", tab: 2)
            }
            .padding(.horizontal, 8)
            .frame(height: 58)
            .background {
                if #unavailable(iOS 26.0) {
                    Color.white
                }
            }
            .clipShape(Capsule())
            .nativeLiquidGlass(in: Capsule(), interactive: true)

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onPlusTapped()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.25))
                    .frame(width: 58, height: 58)
                    .background {
                        if #unavailable(iOS 26.0) {
                            Color.white
                        }
                    }
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .nativeLiquidGlass(in: Circle(), interactive: true)
        }
    }

    private func tabButton(symbol: String, tab: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = tab
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(
                    selectedTab == tab
                        ? Color(red: 0.2, green: 0.2, blue: 0.25)
                        : Color.gray.opacity(0.5)
                )
                .frame(width: 56, height: 42)
                .background(
                    selectedTab == tab ? Color.black.opacity(0.06) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: tab))
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }

    private func accessibilityLabel(for tab: Int) -> String {
        switch tab {
        case 0: "今日"
        case 1: "任务"
        default: "设置"
        }
    }
}
