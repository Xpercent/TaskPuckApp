import SwiftUI
import UIKit

/// 全局统一的任务状态勾选框组件
public struct TaskStatusCheckbox: View {
    public enum Mode {
        /// 标准模式（适合浅色/卡片背景）：彩色边框，选中后彩色填充+白色对勾
        case standard
        /// 反转模式（适合主题色Header背景）：白色边框，选中后白色填充+主题色对勾
        case inverted
    }

    let isDone: Bool
    let tintColor: Color
    let mode: Mode
    let onToggle: () -> Void

    public init(
        isDone: Bool,
        tintColor: Color,
        mode: Mode = .standard,
        onToggle: @escaping () -> Void
    ) {
        self.isDone = isDone
        self.tintColor = tintColor
        self.mode = mode
        self.onToggle = onToggle
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onToggle()
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(borderColor, lineWidth: 3)
                    .frame(width: 24, height: 24)

                if isDone {
                    Circle()
                        .fill(fillColor)
                        .frame(width: 24, height: 24)

                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(checkmarkColor)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isDone ? "标记为未完成" : "标记为已完成")
    }

    private var borderColor: Color {
        mode == .standard ? tintColor : .white
    }

    private var fillColor: Color {
        mode == .standard ? tintColor : .white
    }

    private var checkmarkColor: Color {
        mode == .standard ? .white : tintColor
    }
}

/// 全局统一的模态框关闭按钮
public struct SheetCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary) // 将原本硬编码的 .black 修正为动态语义色 .primary
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .nativeLiquidGlass(in: Circle(), interactive: true)
    }
}

public struct SnappingFormSlider: View {
    @Binding private var selectedIndex: Int
    private let titles: [String]
    private let tintColor: Color
    @State private var lastFeedbackIndex: Int?

    public init(selectedIndex: Binding<Int>, titles: [String], tintColor: Color) {
        self._selectedIndex = selectedIndex
        self.titles = titles
        self.tintColor = tintColor
    }

    public var body: some View {
        GeometryReader { geometry in
            let count = max(titles.count, 1)
            let thumbWidth = max(geometry.size.width / CGFloat(count), 44)
            let trackWidth = max(geometry.size.width - thumbWidth, 1)
            let index = min(max(selectedIndex, 0), count - 1)
            let progress = count > 1 ? CGFloat(index) / CGFloat(count - 1) : 0

            ZStack(alignment: .leading) {
                Capsule().fill(Color(uiColor: .tertiarySystemFill))
                Capsule()
                    .fill(tintColor)
                    .frame(width: thumbWidth, height: 40)
                    .offset(x: trackWidth * progress)
                    .animation(.smooth(duration: 0.2), value: index)

                HStack(spacing: 0) {
                    ForEach(Array(titles.enumerated()), id: \.offset) { offset, title in
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(offset == index ? .white : AppConstants.Colors.textSecondaryDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
            .frame(height: 40)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let normalized = min(max((gesture.location.x - thumbWidth / 2) / trackWidth, 0), 1)
                        let index = Int((normalized * CGFloat(count - 1)).rounded())
                        guard index != selectedIndex else { return }
                        selectedIndex = index
                        if lastFeedbackIndex != index {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            lastFeedbackIndex = index
                        }
                    }
                    .onEnded { _ in lastFeedbackIndex = nil }
            )
        }
        .frame(height: 40)
    }
}
