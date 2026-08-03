import Foundation
import SwiftUI

public struct CreateTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskEngine.self) private var engine

    @State private var taskTitle = ""
    @State private var selectedDurationIndex = 1
    @State private var selectedRecurrenceIndex = 0
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

    private let durations = ["1m", "15m", "30m", "45m", "1h", "1.5h"]
    private let durationMinutesMap = [1, 15, 30, 45, 60, 90]
    private let recurrences = ["仅一次", "每日", "每周", "每月", "日期"]
    private let weekdayOptions: [(Weekday, String)] = [(.sun, "日"), (.mon, "一"), (.tue, "二"), (.wed, "三"), (.thu, "四"), (.fri, "五"), (.sat, "六")]

    public var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 20) {
                durationPicker
                startTimePicker
                recurrencePicker
                recurrenceDetail
                Spacer(minLength: 12)
                createButton
            }
            .padding(.horizontal, 20)
            .background(Color(red: 0.96, green: 0.96, blue: 0.97))
        }
        .ignoresSafeArea()
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            guard let selectedDate = DateUtils.date(from: engine.selectedDateString) else { return }
            onceDate = selectedDate
            rangeStartDate = selectedDate
            rangeEndDate = selectedDate
        }
        .sheet(isPresented: $showsAppearancePicker) {
            AppearancePickerSheet(iconSymbol: $iconSymbol, tintHex: $tintHex)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 50, height: 50)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .nativeLiquidGlass(in: Circle(), interactive: true)
                Spacer()
            }
            .padding(.top, 16)

            HStack(alignment: .center, spacing: 16) {
                Button { showsAppearancePicker = true } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 68, height: 68)
                        Image(systemName: iconSymbol)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color(hex: tintHex))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("选择图标和颜色")

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(durationMinutesMap[selectedDurationIndex])分钟 · \(timeString)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.9))
                    TextField("任务名称", text: $taskTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()
                completionToggle
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 20)
        .frame(height: 230)
        .background(Color(hex: tintHex))
    }

    private var completionToggle: some View {
        Button {
            withAnimation(.spring(response: 0.2)) { isCompleted.toggle() }
        } label: {
            ZStack {
                Circle().stroke(Color.white, lineWidth: 2).frame(width: 26, height: 26)
                if isCompleted {
                    Circle().fill(.white).frame(width: 26, height: 26)
                    Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundStyle(Color(hex: tintHex))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var durationPicker: some View {
        HStack(spacing: 4) {
            ForEach(durations.indices, id: \.self) { index in
                selectionButton(title: durations[index], isSelected: selectedDurationIndex == index) {
                    selectedDurationIndex = index
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.04), in: Capsule())
        .padding(.top, 24)
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
            ForEach(recurrences.indices, id: \.self) { index in
                selectionButton(title: recurrences[index], isSelected: selectedRecurrenceIndex == index) {
                    selectedRecurrenceIndex = index
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.04), in: Capsule())
    }

    @ViewBuilder private var recurrenceDetail: some View {
        switch selectedRecurrenceIndex {
        case 0:
            dateRow(title: "执行日期", selection: $onceDate)
        case 2:
            VStack(alignment: .leading, spacing: 12) {
                Text("重复星期")
                    .font(.system(size: 16, weight: .semibold))
                HStack(spacing: 8) {
                    ForEach(weekdayOptions, id: \.0) { weekday, title in
                        let selected = selectedWeekdays.contains(weekday)
                        Button {
                            if selected { selectedWeekdays.remove(weekday) } else { selectedWeekdays.insert(weekday) }
                        } label: {
                            Text(title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(selected ? .white : .primary)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(selected ? Color(hex: tintHex) : Color.white, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        case 3:
            VStack(alignment: .leading, spacing: 12) {
                Text("重复日期")
                    .font(.system(size: 16, weight: .semibold))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                    ForEach(1...31, id: \.self) { day in
                        monthDayButton(day: day, title: "\(day)")
                    }
                    monthDayButton(day: 0, title: "末")
                }
                .padding(12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        case 4:
            VStack(spacing: 10) {
                dateRow(title: "起始日期", selection: $rangeStartDate)
                dateRow(title: "结束日期", selection: $rangeEndDate, range: rangeStartDate...Date.distantFuture)
            }
        default:
            EmptyView()
        }
    }

    private func monthDayButton(day: Int, title: String) -> some View {
        let selected = selectedMonthDays.contains(day)
        return Button {
            if selected { selectedMonthDays.remove(day) } else { selectedMonthDays.insert(day) }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(selected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(selected ? Color(hex: tintHex) : Color.black.opacity(0.04), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func dateRow(title: String, selection: Binding<Date>, range: ClosedRange<Date>? = nil) -> some View {
        HStack {
            Text(title).font(.system(size: 16, weight: .semibold))
            Spacer()
            if let range {
                DatePicker(title, selection: selection, in: range, displayedComponents: .date).labelsHidden().tint(Color(hex: tintHex))
            } else {
                DatePicker(title, selection: selection, displayedComponents: .date).labelsHidden().tint(Color(hex: tintHex))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func selectionButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { action() }
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
        Button {
            engine.createNewTask(
                title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                durationMinutes: durationMinutesMap[selectedDurationIndex],
                recurrence: selectedRecurrenceRule,
                startTime: storedTimeString,
                iconSymbol: iconSymbol,
                tintHex: tintHex,
                initialStatus: isCompleted ? .done : .todo
            )
            dismiss()
        } label: {
            Text("创建任务")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: tintHex), in: Capsule())
        }
        .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        .padding(.bottom, 28)
    }

    private var timeString: String {
        startTime.formatted(date: .omitted, time: .shortened)
    }

    private var storedTimeString: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private var selectedRecurrenceRule: RecurrenceRule {
        switch selectedRecurrenceIndex {
        case 1: return .daily
        case 2: return .weekly(weekdays: selectedWeekdays.isEmpty ? [.sun] : Array(selectedWeekdays))
        case 3: return .monthlyMultiple(days: selectedMonthDays.isEmpty ? [Calendar.current.component(.day, from: rangeStartDate)] : selectedMonthDays.sorted())
        case 4: return .dateRange(start: DateUtils.string(from: rangeStartDate), end: DateUtils.string(from: max(rangeStartDate, rangeEndDate)), autoArchive: nil)
        default: return .once(date: DateUtils.string(from: onceDate))
        }
    }
}

private struct AppearancePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var iconSymbol: String
    @Binding var tintHex: String
    @State private var showsCustomColor = false

    private let colors = ["EE8C8C", "FF9B70", "F2B500", "90BE6D", "6289AA", "238B6B", "9A426A", "31587C"]
    private let icons = ["checklist", "alarm.fill", "book.fill", "calendar", "bell.fill", "heart.fill", "star.fill", "figure.run", "fork.knife", "moon.fill", "house.fill", "briefcase.fill"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("颜色和图标").font(.system(size: 30, weight: .bold, design: .rounded))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(colors, id: \.self) { color in
                                colorSwatch(color)
                            }
                            Button { showsCustomColor = true } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 50, height: 50)
                                    .background(Color.black.opacity(0.05), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                        ForEach(icons, id: \.self) { symbol in
                            Button { iconSymbol = symbol } label: {
                                ZStack {
                                    Circle().fill(iconSymbol == symbol ? Color(hex: tintHex) : Color.black.opacity(0.05))
                                    Image(systemName: symbol)
                                        .font(.system(size: 25, weight: .semibold))
                                        .foregroundStyle(iconSymbol == symbol ? .white : Color(hex: tintHex))
                                }
                                .frame(height: 64)
                                .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .transaction { $0.animation = nil }
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark").fontWeight(.bold) }
                }
            }
            .sheet(isPresented: $showsCustomColor) {
                CustomColorSheet(tintHex: $tintHex)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func colorSwatch(_ color: String) -> some View {
        Button { tintHex = color } label: {
            Circle().fill(Color(hex: color)).frame(width: 50, height: 50)
                .overlay { if tintHex.uppercased() == color { Circle().stroke(.white, lineWidth: 4).padding(5) } }
        }
        .buttonStyle(.plain)
    }
}

private struct CustomColorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var tintHex: String
    @State private var hue = 0.0
    @State private var brightness = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack {
                Text("选择颜色").font(.system(size: 28, weight: .bold, design: .rounded))
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 18, weight: .bold)).frame(width: 46, height: 46).background(Color.black.opacity(0.05), in: Circle()) }.buttonStyle(.plain)
            }
            HStack(spacing: 10) {
                Text("#").foregroundStyle(Color(hue: hue, saturation: 0.75, brightness: brightness)).font(.title.bold())
                TextField("HEX", text: $tintHex).textInputAutocapitalization(.characters).autocorrectionDisabled().font(.title2.monospaced()).onChange(of: tintHex) { _, newValue in if newValue.count > 6 { tintHex = String(newValue.prefix(6)) } }
            }
            ColorBandSlider(value: $hue, gradient: LinearGradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red], startPoint: .leading, endPoint: .trailing))
            ColorBandSlider(value: $brightness, gradient: LinearGradient(colors: [.black, Color(hue: hue, saturation: 0.8, brightness: 1)], startPoint: .leading, endPoint: .trailing))
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .onAppear { updateSlidersFromHex() }
        .onChange(of: hue) { _, _ in updateHexFromSliders() }
        .onChange(of: brightness) { _, _ in updateHexFromSliders() }
    }

    private func updateSlidersFromHex() {
        let color = UIColor(Color(hex: tintHex))
        var h = CGFloat.zero, s = CGFloat.zero, b = CGFloat.zero, a = CGFloat.zero
        if color.getHue(&h, saturation: &s, brightness: &b, alpha: &a) { hue = h; brightness = b }
    }

    private func updateHexFromSliders() {
        let uiColor = UIColor(hue: hue, saturation: 0.75, brightness: brightness, alpha: 1)
        var red = CGFloat.zero, green = CGFloat.zero, blue = CGFloat.zero, alpha = CGFloat.zero
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        tintHex = String(format: "%02lX%02lX%02lX", red * 255, green * 255, blue * 255)
    }
}

private struct ColorBandSlider: View {
    @Binding var value: Double
    let gradient: LinearGradient

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(gradient).frame(height: 40)
                Circle()
                    .fill(.white)
                    .frame(width: 30, height: 30)
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: max(0, min(width - 30, value * (width - 30))))
            }
            .frame(height: 40)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard width > 30 else { return }
                        value = min(1, max(0, (gesture.location.x - 15) / (width - 30)))
                    }
            )
        }
        .frame(height: 40)
    }
}

private extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted), radix: 16) ?? 0xEE8C8C
        self.init(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }
}
