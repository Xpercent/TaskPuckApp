import SwiftUI

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
        Button(action: onToggle) {
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