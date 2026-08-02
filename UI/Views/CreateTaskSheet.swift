import SwiftUI

public struct CreateTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskEngine.self) private var engine

    @State private var taskTitle: String = "回复邮件"
    @State private var selectedDurationIndex: Int = 1 // 15分钟
    @State private var selectedRecurrenceIndex: Int = 0 // 仅一次

    private let durations = ["1", "15分钟", "30", "45", "1小时", "1.5小时"]
    private let durationMinutesMap = [1, 15, 30, 45, 60, 90]
    private let recurrences = ["仅一次", "每日", "每周", "每月"]

    public var body: some View {
        VStack(spacing: 0) {
            // Top Hero Red/Pink Header Area
            VStack(alignment: .leading, spacing: 16) {
                // Close "X" Button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 36, height: 36)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .padding(.top, 16)

                Spacer()

                // Icon & Title & Checkbox Row
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.85))
                            .frame(width: 64, height: 64)

                        Image(systemName: "at")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.55))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("30分钟 · 收件箱 📥")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.8))

                        TextField("任务名称", text: $taskTitle)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .frame(height: 220)
            .background(Color(red: 0.88, green: 0.52, blue: 0.52))

            // Body Area with Pill Options
            VStack(spacing: 24) {
                // Duration Selectors Segment
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<durations.count, id: \.self) { idx in
                            let isSelected = (idx == selectedDurationIndex)
                            Text(durations[idx])
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isSelected ? .white : Color(red: 0.3, green: 0.3, blue: 0.35))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(isSelected ? Color(red: 0.95, green: 0.55, blue: 0.55) : Color.clear, in: Capsule())
                        }
                    }
                    .padding(6)
                    .background(Color.black.opacity(0.04), in: Capsule())
                }
                .padding(.top, 24)

                // Recurrence Selectors Segment
                HStack(spacing: 8) {
                    ForEach(0..<recurrences.count, id: \.self) { idx in
                        let isSelected = (idx == selectedRecurrenceIndex)
                        Text(recurrences[idx])
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isSelected ? .white : Color(red: 0.3, green: 0.3, blue: 0.35))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color(red: 0.95, green: 0.55, blue: 0.55) : Color.clear, in: Capsule())
                    }
                }
                .padding(6)
                .background(Color.black.opacity(0.04), in: Capsule())

                Spacer()

                // Create Task Bottom Action Button
                Button(action: {
                    let dur = durationMinutesMap[selectedDurationIndex]
                    let rule: RecurrenceRule = selectedRecurrenceIndex == 0 ? .once(date: engine.selectedDateString) : .daily
                    engine.createNewTask(title: taskTitle, durationMinutes: dur, recurrence: rule, startTime: "10:00")
                    dismiss()
                }) {
                    Text("创建任务")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(red: 0.95, green: 0.55, blue: 0.55))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .background(Color(red: 0.96, green: 0.96, blue: 0.97))
        }
        .ignoresSafeArea()
    }
}