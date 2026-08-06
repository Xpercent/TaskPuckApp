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

public struct ContinuousFormSlider: View {
    @Binding private var value: Int
    private let options: [DurationOption]
    private let tintColor: Color
    private let valueTitle: (Int) -> String
    @State private var lastFeedbackValue: Int?

    public init(
        value: Binding<Int>,
        options: [DurationOption],
        tintColor: Color,
        valueTitle: @escaping (Int) -> String
    ) {
        self._value = value
        self.options = options
        self.tintColor = tintColor
        self.valueTitle = valueTitle
    }

    public var body: some View {
        GeometryReader { geometry in
            let thumbDiameter: CGFloat = 40
            let trackWidth = max(geometry.size.width - thumbDiameter, 1)
            let maximum = max(options.last?.minutes ?? 0, 1)
            let progress = min(max(Double(value) / Double(maximum), 0), 1)

            ZStack(alignment: .leading) {
                Capsule().fill(Color(uiColor: .tertiarySystemFill))
                HStack(spacing: 0) {
                    ForEach(options) { option in
                        Text(option.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppConstants.Colors.textSecondaryDark)
                            .frame(maxWidth: .infinity, height: 40)
                    }
                }
                Capsule()
                    .fill(tintColor)
                    .frame(width: thumbDiameter, height: 40)
                    .overlay {
                        Text(valueTitle(value))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .padding(.horizontal, 4)
                    }
                    .offset(x: trackWidth * progress)
            }
            .frame(height: 40)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let normalized = min(max((gesture.location.x - thumbDiameter / 2) / trackWidth, 0), 1)
                        let newValue = Int((normalized * Double(maximum)).rounded())
                        guard newValue != value else { return }
                        value = newValue
                        if lastFeedbackValue != newValue {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            lastFeedbackValue = newValue
                        }
                    }
                    .onEnded { _ in lastFeedbackValue = nil }
            )
        }
        .frame(height: 40)
    }
}

public struct DiscreteFormSlider: View {
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
            let itemWidth = geometry.size.width / CGFloat(count)
            let index = min(max(selectedIndex, 0), count - 1)

            ZStack(alignment: .leading) {
                Capsule().fill(Color(uiColor: .tertiarySystemFill))
                Capsule()
                    .fill(tintColor)
                    .frame(width: itemWidth, height: 40)
                    .offset(x: CGFloat(index) * itemWidth)

                HStack(spacing: 0) {
                    ForEach(Array(titles.enumerated()), id: \.offset) { offset, title in
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(offset == index ? .white : AppConstants.Colors.textSecondaryDark)
                            .frame(width: itemWidth, height: 40)
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
                        let index = min(max(Int(gesture.location.x / max(itemWidth, 1)), 0), count - 1)
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
