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

// MARK: - UIComponents.swift 中的 SnappingFormSlider 替换修改

// MARK: - UIComponents.swift 中的 SnappingFormSlider 替换修改

public struct SnappingFormSlider: View {
    @Binding private var selectedIndex: Int
    private let titles: [String]
    private let tintColor: Color
    private let values: [Int]?
    private let currentValue: Int?
    private let valueTitle: String?
    /// 整体滑轨外框高度
    private let sliderHeight: CGFloat = 48
    /// 内缩边距
    private let innerPadding: CGFloat = 4

    @State private var lastFeedbackIndex: Int?

    public init(
        selectedIndex: Binding<Int>,
        titles: [String],
        tintColor: Color,
        values: [Int]? = nil,
        currentValue: Int? = nil,
        valueTitle: String? = nil
    ) {
        self._selectedIndex = selectedIndex
        self.titles = titles
        self.tintColor = tintColor
        self.values = values
        self.currentValue = currentValue
        self.valueTitle = valueTitle
    }

    public var body: some View {
        GeometryReader { geometry in
            // 内层实际可滚动的有效宽度
            let contentWidth = max(geometry.size.width - innerPadding * 2, 1)
            let count = max(titles.count, 1)
            let thumbWidth = max(contentWidth / CGFloat(count), 44)
            let trackWidth = max(contentWidth - thumbWidth, 1)

            let progress = currentProgress(count: count)
            let innerHeight = sliderHeight - innerPadding * 2 // 内层元素高度 (40pt)

            ZStack(alignment: .leading) {
                // 1. 统一封装的外层滑轨背景 (48pt 高度)
                Capsule().fill(Color(uiColor: .tertiarySystemFill))

                // 2. 内层元素（缩进 4pt，高 40pt）
                ZStack(alignment: .leading) {
                    // 刻度静态文字底纹
                    HStack(spacing: 0) {
                        ForEach(Array(titles.enumerated()), id: \.offset) { _, title in
                            Text(title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppConstants.Colors.textSecondaryDark)
                                .frame(maxWidth: .infinity)
                                .frame(height: innerHeight)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }

                    // 滑块 Thumb
                    Capsule()
                        .fill(tintColor)
                        .frame(width: thumbWidth, height: innerHeight)
                        .overlay(
                            Text(thumbText)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 2)
                        )
                        .offset(x: trackWidth * progress)
                        .animation(.smooth(duration: 0.2), value: progress)
                }
                .padding(innerPadding) // 内缩 4pt 边距
            }
            .frame(height: sliderHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let normalized = min(max((gesture.location.x - innerPadding - thumbWidth / 2) / trackWidth, 0), 1)
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
        .frame(height: sliderHeight)
    }

    /// 计算滑块视觉位置 (0.0 ~ 1.0)
    private func currentProgress(count: Int) -> CGFloat {
        guard count > 1 else { return 0 }

        // 若传入了数值数组和手动输入的精确数值（如 10m），按比例计算介于哪两档之间
        if let values, let currentValue, values.count == titles.count {
            if currentValue <= values[0] { return 0 }
            if let last = values.last, currentValue >= last { return 1 }

            for i in 0..<(values.count - 1) {
                let v0 = values[i]
                let v1 = values[i + 1]
                if currentValue >= v0 && currentValue <= v1 {
                    let fraction = v1 > v0 ? CGFloat(currentValue - v0) / CGFloat(v1 - v0) : 0
                    return (CGFloat(i) + fraction) / CGFloat(count - 1)
                }
            }
        }

        // 默认按选中的离散索引计算
        let index = min(max(selectedIndex, 0), count - 1)
        return CGFloat(index) / CGFloat(count - 1)
    }

    /// 滑块 Thumb 上显示的实时文本
    private var thumbText: String {
        if let valueTitle { return valueTitle }
        let index = min(max(selectedIndex, 0), titles.count - 1)
        return titles.indices.contains(index) ? titles[index] : ""
    }
}