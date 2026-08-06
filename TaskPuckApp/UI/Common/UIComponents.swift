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

public struct SnappingFormSlider: View {
    @Binding private var value: Int
    private let values: [Int]
    private let titles: [String]
    private let tintColor: Color
    private let valueTitleFormatter: (Int) -> String
    private let isDiscreteIndex: Bool
    @State private var lastFeedbackIndex: Int?

    /// 离散索引模式构造函数（如重复频率选择）
    public init(selectedIndex: Binding<Int>, titles: [String], tintColor: Color) {
        self._value = selectedIndex
        self.values = Array(0..<titles.count)
        self.titles = titles
        self.tintColor = tintColor
        self.valueTitleFormatter = { idx in
            titles.indices.contains(idx) ? titles[idx] : ""
        }
        self.isDiscreteIndex = true
    }

    /// 连续数值模式构造函数（如持续时间选择，支持手动非预设值分段比例定位）
    public init(
        value: Binding<Int>,
        values: [Int],
        titles: [String],
        tintColor: Color,
        valueTitleFormatter: ((Int) -> String)? = nil
    ) {
        self._value = value
        self.values = values
        self.titles = titles
        self.tintColor = tintColor
        self.valueTitleFormatter = valueTitleFormatter ?? { val in
            if val == 0 { return "0" }
            let h = val / 60
            let m = val % 60
            if h == 0 { return "\(m)m" }
            if m == 0 { return "\(h)h" }
            return "\(h)h\(m)m"
        }
        self.isDiscreteIndex = false
    }

    public var body: some View {
        GeometryReader { geometry in
            let count = max(titles.count, 1)
            let thumbWidth = max(geometry.size.width / CGFloat(count), 44)
            let trackWidth = max(geometry.size.width - thumbWidth, 1)
            let currentProgress = progress

            ZStack(alignment: .leading) {
                // 1. 轨道背景
                Capsule().fill(Color(uiColor: .tertiarySystemFill))

                // 2. 刻度静态文字底纹
                HStack(spacing: 0) {
                    ForEach(titles, id: \.self) { title in
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppConstants.Colors.textSecondaryDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }

                // 3. 动态滑动块（带有当前实际数值的文本）
                Capsule()
                    .fill(tintColor)
                    .frame(width: thumbWidth, height: 40)
                    .overlay(
                        Text(currentTitle)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 2)
                    )
                    .offset(x: trackWidth * currentProgress)
                    .animation(.smooth(duration: 0.2), value: value)
            }
            .frame(height: 40)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let normalized = min(max((gesture.location.x - thumbWidth / 2) / trackWidth, 0), 1)

                        if isDiscreteIndex {
                            let index = Int((normalized * CGFloat(count - 1)).rounded())
                            guard index != value else { return }
                            value = index
                            if lastFeedbackIndex != index {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                lastFeedbackIndex = index
                            }
                        } else {
                            guard values.count > 1 else { return }
                            let fractionalIndex = normalized * CGFloat(values.count - 1)
                            let segmentIndex = min(Int(fractionalIndex), values.count - 2)
                            let segmentFraction = fractionalIndex - CGFloat(segmentIndex)
                            let v0 = values[segmentIndex]
                            let v1 = values[segmentIndex + 1]
                            let calculatedVal = v0 + Int((segmentFraction * CGFloat(v1 - v0)).rounded())
                            let newStepVal = max(0, calculatedVal)

                            guard newStepVal != value else { return }
                            value = newStepVal
                            let feedbackKey = newStepVal / 5
                            if lastFeedbackIndex != feedbackKey {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                lastFeedbackIndex = feedbackKey
                            }
                        }
                    }
                    .onEnded { _ in lastFeedbackIndex = nil }
            )
        }
        .frame(height: 40)
    }

    /// 计算滑块位置百分比 (0.0 ~ 1.0)
    private var progress: CGFloat {
        guard !values.isEmpty else { return 0 }
        if isDiscreteIndex {
            let count = max(titles.count, 1)
            let idx = min(max(value, 0), count - 1)
            return count > 1 ? CGFloat(idx) / CGFloat(count - 1) : 0
        } else {
            return computeValueProgress(val: value)
        }
    }

    /// 分段线性插值：例如 10m 会精准计算在 0m(index 0) 与 15m(index 1) 之间的 2/3 位置
    private func computeValueProgress(val: Int) -> CGFloat {
        guard values.count > 1 else { return 0 }
        if val <= values[0] { return 0 }
        if let last = values.last, val >= last { return 1 }

        for i in 0..<(values.count - 1) {
            let v0 = values[i]
            let v1 = values[i + 1]
            if val >= v0 && val <= v1 {
                let segmentProgress = v1 > v0 ? CGFloat(val - v0) / CGFloat(v1 - v0) : 0
                let fractionalIndex = CGFloat(i) + segmentProgress
                return fractionalIndex / CGFloat(values.count - 1)
            }
        }
        return 0
    }

    /// 滑块当前显示的文本标题
    private var currentTitle: String {
        if isDiscreteIndex {
            let idx = min(max(value, 0), titles.count - 1)
            return titles.indices.contains(idx) ? titles[idx] : ""
        } else {
            // 若刚好匹配预设值（如 90 分钟匹配 1.5h），优先显示预设标题；否则显示格式化后的具体数值（如 10m）
            if let idx = values.firstIndex(of: value), titles.indices.contains(idx) {
                return titles[idx]
            }
            return valueTitleFormatter(value)
        }
    }
}