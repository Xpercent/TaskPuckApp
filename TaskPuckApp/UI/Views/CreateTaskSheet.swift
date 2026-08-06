import Foundation
import SwiftUI

public struct CreateTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskEngine.self) private var engine
    @AppStorage(AppConstants.StorageKeys.appThemeHex) private var themeHex = AppConstants.Appearance.defaultTintHex

    @State private var taskTitle = ""
    @State private var selectedDurationMinutes = 0
    @State private var selectedRecurrence = RecurrenceOption.once
    @State private var startTime = Date()
    @State private var hasStartTime = true
    @State private var notificationsEnabled = false
    @State private var showsDurationPicker = false
    @State private var onceDate = Date()
    @State private var rangeStartDate = Date()
    @State private var rangeEndDate = Date()
    @State private var selectedWeekdays: Set<Weekday> = []
    @State private var selectedMonthDays: Set<Int> = []
    @State private var isDone = false
    @State private var iconSymbol = AppConstants.Appearance.defaultIconSymbol
    @State private var tintHex = AppConstants.Appearance.defaultTintHex
    @State private var showsAppearancePicker = false
    @AppStorage(AppConstants.StorageKeys.lastDurationMinutes) private var lastDurationMinutes = 0
    @AppStorage(AppConstants.StorageKeys.lastHasStartTime) private var lastHasStartTime = true
    @AppStorage(AppConstants.StorageKeys.lastRecurrenceIndex) private var lastRecurrenceIndex = 0
    @AppStorage(AppConstants.StorageKeys.lastNotificationsEnabled) private var lastNotificationsEnabled = false

    private let editingTask: TaskEntity?
    private let editingStatus: InstanceStatus

    public init() {
        self.editingTask = nil
        self.editingStatus = .todo
    }

    init(task: TaskEntity, status: InstanceStatus = .todo) {
        self.editingTask = task
        self.editingStatus = status
    }

    private var durationOptions: [DurationOption] {
        AppConstants.TaskForm.durationOptions
    }

    private var weekdayOptions: [WeekdayOption] {
        AppConstants.TaskForm.weekdayOptions
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        durationSetting
                        if !showsDurationPicker {
                            durationPicker
                        }
                        startTimePicker
                        notificationSetting
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
        .background(AppConstants.Colors.backgroundGrey)
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: initializeForm)
        .onChange(of: selectedDurationMinutes) { _, value in
            guard editingTask == nil else { return }
            lastDurationMinutes = value
        }
        .onChange(of: hasStartTime) { _, value in
            guard editingTask == nil else { return }
            lastHasStartTime = value
        }
        .onChange(of: selectedRecurrence) { _, value in
            guard editingTask == nil else { return }
            lastRecurrenceIndex = RecurrenceOption.allCases.firstIndex(of: value) ?? 0
        }
        .onChange(of: notificationsEnabled) { _, value in
            guard editingTask == nil else { return }
            lastNotificationsEnabled = value
        }
        .sheet(isPresented: $showsAppearancePicker) {
            AppearancePickerSheet(iconSymbol: $iconSymbol, tintHex: $tintHex)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SheetCloseButton()
                Spacer()
            }
            .padding(.top, 16)

            HStack(alignment: .center, spacing: 16) {
                Button {
                    showsAppearancePicker = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.white.opacity(0.9))
                            .frame(width: 64, height: 64)
                        Image(systemName: iconSymbol)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color(hex: tintHex))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("选择图标和颜色")

                VStack(alignment: .leading, spacing: 6) {
                    Text(placementSummary)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    TextField("任务名称", text: $taskTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()
                TaskStatusCheckbox(
                    isDone: isDone,
                    tintColor: Color(hex: tintHex),
                    mode: .inverted
                ) {
                    isDone.toggle()
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .frame(height: 180)
        .background(Color(hex: tintHex))
    }

    private var durationPicker: some View {
        SnappingFormSlider(
            selectedIndex: durationIndex,
            titles: durationOptions.map(\.title),
            tintColor: Color(hex: tintHex),
            values: durationOptions.map(\.minutes),
            currentValue: selectedDurationMinutes,
            valueTitle: durationThumbTitle
        )
    }

    private var durationThumbTitle: String {
        if let option = durationOptions.first(where: { $0.minutes == selectedDurationMinutes }) {
            return option.title
        }
        let h = selectedDurationMinutes / 60
        let m = selectedDurationMinutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h\(m)m"
    }

    private var durationDateBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = durationHours.wrappedValue
                components.minute = durationRemainderMinutes.wrappedValue
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                durationHours.wrappedValue = components.hour ?? 0
                durationRemainderMinutes.wrappedValue = components.minute ?? 0
            }
        )
    }

    private var durationSetting: some View {
        HStack {
            Label("持续时间", systemImage: "timer")
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            DatePicker("持续时间", selection: durationDateBinding, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Color(hex: tintHex))
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        // 修正：使用全局卡片背景色
        .background(AppConstants.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var startTimePicker: some View {
        HStack(spacing: 12) {
            Label("开始时间", systemImage: "clock")
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            DatePicker("开始时间", selection: $startTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Color(hex: tintHex))
                .opacity(hasStartTime ? 1 : 0)
                .disabled(!hasStartTime)

            Toggle("", isOn: $hasStartTime)
                .labelsHidden()
                .tint(Color(hex: tintHex))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        // 修正：使用全局卡片背景色
        .background(AppConstants.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var recurrencePicker: some View {
        SnappingFormSlider(
            selectedIndex: recurrenceIndex,
            titles: RecurrenceOption.allCases.map(\.title),
            tintColor: Color(hex: tintHex)
        )
    }

    private var notificationSetting: some View {
        HStack(spacing: 12) {
            Label(AppConstants.TaskForm.notificationTitle, systemImage: AppConstants.TaskForm.notificationIconSymbol)
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            Toggle(AppConstants.TaskForm.notificationTitle, isOn: $notificationsEnabled)
                .labelsHidden()
                .tint(Color(hex: tintHex))
                .disabled(!hasStartTime)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(AppConstants.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onChange(of: notificationsEnabled) { _, enabled in
            if enabled {
                TaskNotificationScheduler.requestAuthorization()
            }
        }
        .onChange(of: hasStartTime) { _, value in
            if !value {
                notificationsEnabled = false
            }
        }
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
                                // 修正：未选中时采用全局卡片背景色
                                .background(isSelected ? Color(hex: tintHex) : AppConstants.Colors.cardBackground, in: Circle())
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
                // 修正：使用全局卡片背景色
                .background(AppConstants.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                // 修正：未选中状态使用系统自适应透明前景背景
                .background(isSelected ? Color(hex: tintHex) : Color.primary.opacity(0.06), in: Circle())
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
        // 修正：使用全局卡片背景色
        .background(AppConstants.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                .foregroundStyle(isSelected ? .white : AppConstants.Colors.textSecondaryDark)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? Color(hex: tintHex) : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var createButton: some View {
        Group {
            if editingTask == nil {
                actionButton(title: "创建任务", color: Color(hex: tintHex), action: createTask)
            } else {
                HStack(spacing: 12) {
                    actionButton(title: "删除", color: .red, action: deleteTask)
                    actionButton(title: "更新", color: Color(hex: tintHex), action: updateTask)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        let requiresTaskDetails = title == "创建任务" || title == "更新"
        let isDisabled = requiresTaskDetails && (
            normalizedTaskTitle.isEmpty || !hasStartTime || recurrenceSelectionInvalid
        )

        return Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isDisabled ? Color.white.opacity(0.7) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    isDisabled ? color.lighterColor() : color,
                    in: Capsule()
                )
        }
        .disabled(isDisabled)
    }

    private var normalizedTaskTitle: String {
        taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var recurrenceSelectionInvalid: Bool {
        switch selectedRecurrence {
        case .weekly:
            selectedWeekdays.isEmpty
        case .monthly:
            selectedMonthDays.isEmpty
        default:
            false
        }
    }

    private var placementSummary: String {
        let time = hasStartTime ? timeString : "无开始时间"
        return "\(durationDescription) · \(time)"
    }

    private var timeString: String {
        startTime.formatted(date: .omitted, time: .shortened)
    }

    private var storedTimeString: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private var durationDescription: String {
        guard selectedDurationMinutes > 0 else { return "无" }
        let hours = selectedDurationMinutes / 60
        let minutes = selectedDurationMinutes % 60
        if hours == 0 { return "\(minutes) 分钟" }
        if minutes == 0 { return "\(hours) 小时" }
        return "\(hours) 小时 \(minutes) 分钟"
    }

    private var durationHours: Binding<Int> {
        Binding(
            get: { selectedDurationMinutes / 60 },
            set: { selectedDurationMinutes = $0 * 60 + selectedDurationMinutes % 60 }
        )
    }

    private var durationRemainderMinutes: Binding<Int> {
        Binding(
            get: { selectedDurationMinutes % 60 },
            set: { selectedDurationMinutes = selectedDurationMinutes / 60 * 60 + $0 }
        )
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

    private func initializeForm() {
        if let editingTask {
            load(editingTask)
            return
        }

        guard let selectedDate = DateUtils.date(from: engine.selectedDateString) else { return }
        onceDate = selectedDate
        rangeStartDate = selectedDate
        rangeEndDate = selectedDate
        isDone = false
        tintHex = themeHex
        selectedDurationMinutes = lastDurationMinutes
        hasStartTime = lastHasStartTime
        notificationsEnabled = lastNotificationsEnabled
        if RecurrenceOption.allCases.indices.contains(lastRecurrenceIndex) {
            selectedRecurrence = RecurrenceOption.allCases[lastRecurrenceIndex]
        }
    }

    private func createTask() {
        engine.createNewTask(
            title: normalizedTaskTitle,
            durationMinutes: selectedDurationMinutes,
            recurrence: selectedRecurrenceRule,
            startTime: hasStartTime ? storedTimeString : nil,
            iconSymbol: iconSymbol,
            tintHex: tintHex,
            notificationsEnabled: notificationsEnabled,
            initialStatus: isDone ? .done : .todo
        )
        rememberFormPreferences()
        dismiss()
    }

    private func updateTask() {
        guard let editingTask else { return }
        engine.updateTask(
            editingTask,
            title: normalizedTaskTitle,
            durationMinutes: selectedDurationMinutes,
            recurrence: selectedRecurrenceRule,
            startTime: hasStartTime ? storedTimeString : nil,
            iconSymbol: iconSymbol,
            tintHex: tintHex,
            notificationsEnabled: notificationsEnabled
        )
        if let instance = engine.managedTasks(for: .today).first(where: { $0.task.id == editingTask.id })?.instance,
           (instance.status == .done) != isDone {
            engine.toggleTaskStatus(instance: instance)
        }
        dismiss()
    }

    private func deleteTask() {
        guard let editingTask else { return }
        engine.deleteTask(editingTask)
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

    private var recurrenceIndex: Binding<Int> {
        Binding(
            get: { RecurrenceOption.allCases.firstIndex(of: selectedRecurrence) ?? 0 },
            set: { selectedRecurrence = RecurrenceOption.allCases[$0] }
        )
    }

    private func rememberFormPreferences() {
        lastDurationMinutes = selectedDurationMinutes
        lastHasStartTime = hasStartTime
        lastRecurrenceIndex = RecurrenceOption.allCases.firstIndex(of: selectedRecurrence) ?? 0
        lastNotificationsEnabled = notificationsEnabled
    }

    private var durationIndex: Binding<Int> {
        Binding(
            get: {
                durationOptions.enumerated().min {
                    abs($0.element.minutes - selectedDurationMinutes) < abs($1.element.minutes - selectedDurationMinutes)
                }?.offset ?? 0
            },
            set: { selectedDurationMinutes = durationOptions[$0].minutes }
        )
    }

    private func load(_ task: TaskEntity) {
        taskTitle = task.title
        iconSymbol = task.iconSymbol
        tintHex = task.tintHex
        notificationsEnabled = task.notificationsEnabled
        isDone = editingStatus == .done

        if let placement = task.defaultPlacement {
            selectedDurationMinutes = placement.duration
            startTime = date(for: placement.startTime)
            hasStartTime = true
        } else {
            selectedDurationMinutes = 0
            hasStartTime = false
            notificationsEnabled = false
        }

        guard let rule = task.recurrenceRules.first else { return }
        switch rule {
        case .daily:
            selectedRecurrence = .daily
        case .weekly(let weekdays):
            selectedRecurrence = .weekly
            selectedWeekdays = Set(weekdays)
        case .monthly(let day):
            selectedRecurrence = .monthly
            selectedMonthDays = [day]
        case .monthlyMultiple(let days):
            selectedRecurrence = .monthly
            selectedMonthDays = Set(days)
        case .once(let date):
            selectedRecurrence = .once
            onceDate = DateUtils.date(from: date) ?? onceDate
        case .dateRange(let start, let end, _):
            selectedRecurrence = .dateRange
            rangeStartDate = DateUtils.date(from: start) ?? rangeStartDate
            rangeEndDate = DateUtils.date(from: end) ?? rangeEndDate
        }
    }

    private func date(for time: String) -> Date {
        let components = time.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return Date() }
        return Calendar.current.date(
            bySettingHour: components[0],
            minute: components[1],
            second: 0,
            of: Date()
        ) ?? Date()
    }
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
