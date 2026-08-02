import SwiftUI

public struct CreateTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskEngine.self) private var engine

    @State private var taskTitle: String = ""
    @State private var selectedDurationIndex: Int = 1 // 15分钟
    @State private var selectedRecurrenceIndex: Int = 0 // 仅一次
    @State private var isCompleted: Bool = false

    private let durations = ["1m", "15m", "30m", "45m", "1h", "1.5h"]
    private let durationMinutesMap = [1, 15, 30, 45, 60, 90]
    private let recurrences = ["仅一次", "每日", "每周", "每月"]

    public var body: some View {
        VStack(spacing: 0) {
            // 顶部粉红 Hero 卡片区
            VStack(alignment: .leading, spacing: 20) {
                // 关闭按钮
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .nativeLiquidGlass(in: Circle(), interactive: true)
                .padding(.top, 16)

                Spacer()

                // 图标 + 标题输入框 + 打勾按钮
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 68, height: 68)

                        Image(systemName: "at")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Color(red: 0.93, green: 0.55, blue: 0.55))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Text("\(durationMinutesMap[selectedDurationIndex])分钟 · 收件箱")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.9))
                            Image(systemName: "tray.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.9))
                        }

                        TextField("任务名称", text: $taskTitle)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // 右侧完成状态切换按钮
                    Button(action: {
                        withAnimation(.spring(response: 0.2)) {
                            isCompleted.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 26, height: 26)

                            if isCompleted {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 26, height: 26)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(red: 0.88, green: 0.52, blue: 0.52))
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .frame(height: 230)
            .background(Color(red: 0.88, green: 0.52, blue: 0.52))

            // 选项选择区
            VStack(spacing: 20) {
                // 时间时长选择器（非 ScrollView，完全等宽塞满容器，支持点击切换）
                HStack(spacing: 4) {
                    ForEach(0..<durations.count, id: \.self) { idx in
                        let isSelected = (idx == selectedDurationIndex)
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDurationIndex = idx
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            Text(durations[idx])
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(isSelected ? .white : Color(red: 0.25, green: 0.25, blue: 0.3))
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(
                                    isSelected ? Color(red: 0.93, green: 0.55, blue: 0.55) : Color.clear,
                                    in: Capsule()
                                )
                        }
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.04), in: Capsule())
                .padding(.top, 24)

                // 重复规则选择器（等宽平铺，支持点击切换）
                HStack(spacing: 4) {
                    ForEach(0..<recurrences.count, id: \.self) { idx in
                        let isSelected = (idx == selectedRecurrenceIndex)
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedRecurrenceIndex = idx
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            Text(recurrences[idx])
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isSelected ? .white : Color(red: 0.25, green: 0.25, blue: 0.3))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    isSelected ? Color(red: 0.93, green: 0.55, blue: 0.55) : Color.clear,
                                    in: Capsule()
                                )
                        }
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.04), in: Capsule())

                Spacer()

                // 创建任务主按钮
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    let dur = durationMinutesMap[selectedDurationIndex]
                    let rule = selectedRecurrenceRule
                    engine.createNewTask(
                        title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                        durationMinutes: dur,
                        recurrence: rule,
                        initialStatus: isCompleted ? .done : .todo
                    )
                    dismiss()
                }) {
                    Text("创建任务")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.93, green: 0.55, blue: 0.55))
                        .clipShape(Capsule())
                        .shadow(color: Color(red: 0.93, green: 0.55, blue: 0.55).opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 20)
            .background(Color(red: 0.96, green: 0.96, blue: 0.97))
        }
        .ignoresSafeArea()
    }

    private var selectedRecurrenceRule: RecurrenceRule {
        guard let selectedDate = DateUtils.date(from: engine.selectedDateString) else {
            return .once(date: engine.selectedDateString)
        }

        switch selectedRecurrenceIndex {
        case 1:
            return .daily
        case 2:
            let weekday = DateUtils.calendar.component(.weekday, from: selectedDate)
            let weekdays: [Weekday] = [.sun, .mon, .tue, .wed, .thu, .fri, .sat]
            return .weekly(weekdays: [weekdays[weekday - 1]])
        case 3:
            return .monthly(day: DateUtils.calendar.component(.day, from: selectedDate))
        default:
            return .once(date: engine.selectedDateString)
        }
    }
}
