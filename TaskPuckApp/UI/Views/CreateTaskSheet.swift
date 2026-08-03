import Foundation
import SwiftUI

public struct CreateTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskEngine.self) private var engine

    @State private var taskTitle = ""
    @State private var selectedDurationMinutes = 15
    @State private var selectedRecurrence = RecurrenceOption.once
    @State private var startTime = Date()
    @State private var onceDate = Date()
    @State private var rangeStartDate = Date()
    @State private var rangeEndDate = Date()
    @State private var selectedWeekdays: Set<Weekday> = []
    @State private var selectedMonthDays: Set<Int> = []
    @State private var isCompleted = false
    @State private var iconSymbol = "checklist"
    @State private var tintHex = "EE8C8C"
    @State private var showsAppearancePicker = false

    private let durationOptions = [
        DurationOption(title: "1m", minutes: 1),
        DurationOption(title: "15m", minutes: 15),
        DurationOption(title: "30m", minutes: 30),
        DurationOption(title: "45m", minutes: 45),
        DurationOption(title: "1h", minutes: 60),
        DurationOption(title: "1.5h", minutes: 90)
    ]

    private let weekdayOptions = [
        WeekdayOption(weekday: .sun, title: "日"),
        WeekdayOption(weekday: .mon, title: "一"),
        WeekdayOption(weekday: .tue, title: "二"),
        WeekdayOption(weekday: .wed, title: "三"),
        WeekdayOption(weekday: .thu, title: "四"),
        WeekdayOption(weekday: .fri, title: "五"),
        WeekdayOption(weekday: .sat, title: "六")
    ]

    public var body: some View {
        VStack(spacing: 0) {
            header

            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        durationPicker
                        startTimePicker
                        recurrencePicker
                        recurrenceDetail
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 90)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .mask(
                    VStack(spacing: 0) {
                        Color.black
                        LinearGradient(
                            colors: [.black, .black.opacity(0.6), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                    }
                )

                createButton
            }
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97))
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: initializeDates)
        .sheet(isPresented: $showsAppearancePicker) {
            AppearancePickerSheet(iconSymbol: $iconSymbol, tintHex: $tintHex)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .nativeLiquidGlass(in: Circle(), interactive: true)

                Spacer()
            }
            .padding(.top, 16)

            HStack(alignment: .center, spacing: 16) {
                Button {
                    showsAppearancePicker = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 64, height: 64)
                        Image(systemName: iconSymbol)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color(hex: tintHex))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("选择图标和颜色")

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(selectedDurationMinutes)分钟 · \(timeString)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.9))
                    TextField("任务名称", text: $taskTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()
                completionToggle
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .frame(height: 180)
        .background(Color(hex: tintHex))
    }

    private var completionToggle: some View {
        Button {
            withAnimation(.smooth(duration: 0.2)) {
                isCompleted.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 26, height: 26)

                if isCompleted {
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: tintHex))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCompleted ? "标记为未完成" : "标记为已完成")
    }

    private var durationPicker: some View {
        HStack(spacing: 4) {
            ForEach(durationOptions) { option in
                selectionButton(
                    title: option.title,
                    isSelected: selectedDurationMinutes == option.minutes
                ) {
                    selectedDurationMinutes = option.minutes
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.04), in: Capsule())
    }

    private var startTimePicker: some View {
        HStack {
            Label("开始时间", systemImage: "clock")
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            DatePicker("开始时间", selection: $startTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Color(hex: tintHex))
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var recurrencePicker: some View {
        HStack(spacing: 4) {
            ForEach(RecurrenceOption.allCases) { option in
                selectionButton(title: option.title, isSelected: selectedRecurrence == option) {
                    selectedRecurrence = option
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.04), in: Capsule())
    }

    @ViewBuilder private var recurrenceDetail: some View {
        switch selectedRecurrence {
        case .once:
            dateRow(title: "执行日期", selection: $onceDate)
        case .daily:
            EmptyView()
        case .weekly:
            VStack(alignment: .leading, spacing: 12) {
                Text("重复星期")
                    .font(.system(size: 16, weight: .semibold))
                HStack(spacing: 8) {
                    ForEach(weekdayOptions) { option in
                        let isSelected = selectedWeekdays.contains(option.weekday)
                        Button {
                            toggleWeekday(option.weekday)
                        } label: {
                            Text(option.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(isSelected ? .white : .primary)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(isSelected ? Color(hex: tintHex) : Color.white, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        case .monthly:
            VStack(alignment: .leading, spacing: 12) {
                Text("重复日期")
                    .font(.system(size: 16, weight: .semibold))
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                    spacing: 8
                ) {
                    ForEach(1...31, id: \.self) { day in
                        monthDayButton(day: day, title: "\(day)")
                    }
                    monthDayButton(day: 0, title: "末")
                }
                .padding(12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        case .dateRange:
            VStack(spacing: 10) {
                dateRow(title: "起始日期", selection: $rangeStartDate)
                dateRow(
                    title: "结束日期",
                    selection: $rangeEndDate,
                    range: rangeStartDate...Date.distantFuture
                )
            }
        }
    }

    private func monthDayButton(day: Int, title: String) -> some View {
        let isSelected = selectedMonthDays.contains(day)
        return Button {
            toggleMonthDay(day)
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(isSelected ? Color(hex: tintHex) : Color.black.opacity(0.04), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func dateRow(
        title: String,
        selection: Binding<Date>,
        range: ClosedRange<Date>? = nil
    ) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            if let range {
                DatePicker(title, selection: selection, in: range, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Color(hex: tintHex))
            } else {
                DatePicker(title, selection: selection, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Color(hex: tintHex))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func selectionButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.2)) {
                action()
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Color(red: 0.25, green: 0.25, blue: 0.3))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? Color(hex: tintHex) : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var createButton: some View {
        Button(action: createTask) {
            Text("创建任务")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: tintHex), in: Capsule())
        }
        .disabled(normalizedTaskTitle.isEmpty)
        .opacity(normalizedTaskTitle.isEmpty ? 0.5 : 1)
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    private var normalizedTaskTitle: String {
        taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var timeString: String {
        startTime.formatted(date: .omitted, time: .shortened)
    }

    private var storedTimeString: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private var selectedRecurrenceRule: RecurrenceRule {
        switch selectedRecurrence {
        case .once:
            return .once(date: DateUtils.string(from: onceDate))
        case .daily:
            return .daily
        case .weekly:
            return .weekly(weekdays: selectedWeekdays.isEmpty ? [.sun] : Array(selectedWeekdays))
        case .monthly:
            let fallbackDay = Calendar.current.component(.day, from: onceDate)
            return .monthlyMultiple(days: selectedMonthDays.isEmpty ? [fallbackDay] : selectedMonthDays.sorted())
        case .dateRange:
            return .dateRange(
                start: DateUtils.string(from: rangeStartDate),
                end: DateUtils.string(from: max(rangeStartDate, rangeEndDate)),
                autoArchive: nil
            )
        }
    }

    private func initializeDates() {
        guard let selectedDate = DateUtils.date(from: engine.selectedDateString) else { return }
        onceDate = selectedDate
        rangeStartDate = selectedDate
        rangeEndDate = selectedDate
    }

    private func createTask() {
        engine.createNewTask(
            title: normalizedTaskTitle,
            durationMinutes: selectedDurationMinutes,
            recurrence: selectedRecurrenceRule,
            startTime: storedTimeString,
            iconSymbol: iconSymbol,
            tintHex: tintHex,
            initialStatus: isCompleted ? .done : .todo
        )
        dismiss()
    }

    private func toggleWeekday(_ weekday: Weekday) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
    }

    private func toggleMonthDay(_ day: Int) {
        if selectedMonthDays.contains(day) {
            selectedMonthDays.remove(day)
        } else {
            selectedMonthDays.insert(day)
        }
    }
}

private struct DurationOption: Identifiable {
    let title: String
    let minutes: Int

    var id: Int { minutes }
}

private struct WeekdayOption: Identifiable {
    let weekday: Weekday
    let title: String

    var id: Weekday { weekday }
}

private enum RecurrenceOption: CaseIterable, Hashable, Identifiable {
    case once
    case daily
    case weekly
    case monthly
    case dateRange

    var id: Self { self }

    var title: String {
        switch self {
        case .once: "仅一次"
        case .daily: "每日"
        case .weekly: "每周"
        case .monthly: "每月"
        case .dateRange: "日期"
        }
    }
}
