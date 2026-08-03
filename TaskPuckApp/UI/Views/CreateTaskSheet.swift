import Foundation
import SwiftUI
import UIKit

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
            // 固定顶部的 Header 颜色区域
            header

            // 下方可滚动表单
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    durationPicker
                    startTimePicker
                    recurrencePicker
                    recurrenceDetail
                    Spacer(minLength: 20)
                    createButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.97))
        }
        .ignoresSafeArea(.keyboard)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { dismiss() } label: {
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
                Button { showsAppearancePicker = true } label: {
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
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .frame(height: 180)
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

// 高性能无动画 ButtonStyle，彻底解决快速点击背景闪烁问题
private struct NoAnimButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
    }
}

private struct AppearancePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var iconSymbol: String
    @Binding var tintHex: String
    @State private var showsCustomColor = false

    private let colors = ["EE8C8C", "FF9B70", "F2B500", "90BE6D", "6289AA", "238B6B", "9A426A", "31587C"]
    private let icons = [
        "checklist", "alarm.fill", "book.fill", "calendar", "bell.fill",
        "heart.fill", "star.fill", "figure.run", "fork.knife", "moon.fill",
        "house.fill", "briefcase.fill", "flame.fill", "drop.fill", "leaf.fill"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("颜色和图标")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .padding(.top, 4)

                    // 图二样式预设色盘容器
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                let isSelected = tintHex.uppercased() == color.uppercased()
                                Button {
                                    var transaction = Transaction()
                                    transaction.disablesAnimations = true
                                    withTransaction(transaction) {
                                        tintHex = color
                                    }
                                } label: {
                                    ZStack {
                                        if isSelected {
                                            Circle()
                                                .stroke(Color(hex: color), lineWidth: 2.5)
                                                .frame(width: 42, height: 42)
                                            Circle()
                                                .fill(Color(hex: color))
                                                .frame(width: 32, height: 32)
                                        } else {
                                            Circle()
                                                .fill(Color(hex: color))
                                                .frame(width: 38, height: 38)
                                        }
                                    }
                                    .frame(width: 42, height: 42)
                                }
                                .buttonStyle(NoAnimButtonStyle())
                            }

                            Button { showsCustomColor = true } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.06))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(NoAnimButtonStyle())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                    .background(Color.black.opacity(0.04), in: Capsule())
                    .clipShape(Capsule()) // 彻底裁切溢出胶囊框外的色块

                    // 每行 5 个精简图标网格
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 14) {
                        ForEach(icons, id: \.self) { symbol in
                            let isSelected = iconSymbol == symbol
                            Button {
                                var transaction = Transaction()
                                transaction.disablesAnimations = true
                                withTransaction(transaction) {
                                    iconSymbol = symbol
                                }
                            } label: {
                                ZStack {
                                    // 1. 固定存在的灰色底层圈，绝不消失
                                    Circle()
                                        .fill(Color.black.opacity(0.05))

                                    // 2. 选中的主题色覆盖圈，通过 opacity 平滑显隐
                                    Circle()
                                        .fill(Color(hex: tintHex))
                                        .opacity(isSelected ? 1.0 : 0.0)

                                    Image(systemName: symbol)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(isSelected ? .white : Color(hex: tintHex))
                                }
                                .frame(height: 52)
                                .contentShape(Circle())
                            }
                            .buttonStyle(NoAnimButtonStyle())
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            // 1. AppearancePickerSheet 右上角关闭按钮：
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 38, height: 38)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .nativeLiquidGlass(in: Circle(), interactive: true)
                }
            }
            .sheet(isPresented: $showsCustomColor) {
                CustomColorSheet(tintHex: $tintHex, iconSymbol: iconSymbol)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

private struct CustomColorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var tintHex: String
    var iconSymbol: String = "checklist"

    @State private var hue: Double = 0.0
    @State private var saturation: Double = 0.75
    @State private var brightness: Double = 0.95
    @State private var hexInputText: String = ""

    // 预设颜色（完全匹配图三）
    private let presetColors = [
        "F49898", "FF9D73", "E0A800", "8CBD68",
        "5E86A8", "1A8B6B", "8D3F68", "2C4A6F",
        "000000"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Header: 标题、HEX展示与关闭按钮 (图三样式)
            HStack(alignment: .center) {
                Text("选择颜色")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Text("#")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(red: 0.9, green: 0.4, blue: 0.4))
                    
                    TextField("HEX", text: $hexInputText)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .frame(width: 90)
                        .onChange(of: hexInputText) { newValue in
                            let cleaned = newValue.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
                            if cleaned.count <= 6 { hexInputText = cleaned }
                            if cleaned.count == 6 {
                                tintHex = cleaned
                                syncHSBFromHex(cleaned)
                            }
                        }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.black.opacity(0.2))
                        .frame(height: 1)
                }

                Spacer().frame(width: 12)

                // 2. CustomColorSheet 右上角关闭按钮：
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 38, height: 38)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .nativeLiquidGlass(in: Circle(), interactive: true)
            }

            // Slider 1: 彩虹 Hue 色彩光谱条
            ColorSpectrumSlider(hue: $hue) {
                updateHexFromHSB()
            }

            // Slider 2: 亮度/暗度条
            ColorBrightnessSlider(hue: hue, saturation: $saturation, brightness: $brightness) {
                updateHexFromHSB()
            }

            // 预设 Headers (对标图三)
            HStack {
                Text("预设")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()

                Button { } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("编辑")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.05), in: Capsule())
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)

            // 预设块网格 + 左侧贯穿竖线图标指示圈 (对标图三)
            HStack(alignment: .top, spacing: 20) {
                ZStack {
                    Rectangle()
                        .fill(Color(hex: tintHex).opacity(0.3))
                        .frame(width: 2, height: 125)

                    Circle()
                        .fill(Color(hex: tintHex))
                        .frame(width: 52, height: 52)
                        .shadow(color: Color(hex: tintHex).opacity(0.3), radius: 6, y: 3)
                        .overlay {
                            Image(systemName: iconSymbol)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        }
                }
                .frame(width: 52)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(38), spacing: 16), count: 4), alignment: .leading, spacing: 16) {
                    ForEach(presetColors, id: \.self) { colorHex in
                        Button {
                            tintHex = colorHex
                            hexInputText = colorHex
                            syncHSBFromHex(colorHex)
                        } label: {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 38, height: 38)
                                .overlay {
                                    if tintHex.uppercased() == colorHex.uppercased() {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2.5)
                                            .shadow(color: .black.opacity(0.2), radius: 2)
                                    }
                                }
                        }
                        .buttonStyle(NoAnimButtonStyle())
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .onAppear {
            hexInputText = tintHex.uppercased()
            syncHSBFromHex(tintHex)
        }
    }

    private func syncHSBFromHex(_ hex: String) {
        if let hsb = hexToHSB(hex) {
            self.hue = hsb.h
            self.saturation = hsb.s
            self.brightness = hsb.b
        }
    }

    private func updateHexFromHSB() {
        let newHex = hsbToHex(h: hue, s: saturation, b: brightness)
        self.tintHex = newHex
        self.hexInputText = newHex
    }
}

private struct ColorSpectrumSlider: View {
    @Binding var hue: Double
    var currentColorHex: String
    var onChange: () -> Void

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let handleSize: CGFloat = 32
            let travelWidth = max(1, width - handleSize)
            let currentX = CGFloat(hue) * travelWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 32)

                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: handleSize, height: handleSize)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    Circle()
                        .fill(Color(hex: currentColorHex))
                        .frame(width: handleSize - 6, height: handleSize - 6)
                }
                .offset(x: currentX)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newX = max(0, min(travelWidth, value.location.x - handleSize / 2))
                            hue = Double(newX / travelWidth)
                            onChange()
                        }
                )
            }
        }
        .frame(height: 32)
    }
}

private struct ColorBrightnessSlider: View {
    var hue: Double
    @Binding var saturation: Double
    @Binding var brightness: Double
    var currentColorHex: String
    var onChange: () -> Void

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let handleSize: CGFloat = 32
            let travelWidth = max(1, width - handleSize)
            let currentX = CGFloat(brightness) * travelWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.black, Color(hue: hue, saturation: max(0.5, saturation), brightness: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 32)

                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: handleSize, height: handleSize)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    Circle()
                        .fill(Color(hex: currentColorHex))
                        .frame(width: handleSize - 6, height: handleSize - 6)
                }
                .offset(x: currentX)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newX = max(0, min(travelWidth, value.location.x - handleSize / 2))
                            brightness = Double(newX / travelWidth)
                            onChange()
                        }
                )
            }
        }
        .frame(height: 32)
    }
}

// 基于 UIColor 的精准 HSB/RGB 转换函数
private func hexToHSB(_ hex: String) -> (h: Double, s: Double, b: Double)? {
    let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    guard cleanHex.count == 6, let val = UInt64(cleanHex, radix: 16) else { return nil }
    let r = CGFloat((val >> 16) & 0xFF) / 255.0
    let g = CGFloat((val >> 8) & 0xFF) / 255.0
    let b = CGFloat((val) & 0xFF) / 255.0
    let uiColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)
    var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0, a: CGFloat = 0
    if uiColor.getHue(&h, saturation: &s, brightness: &br, alpha: &a) {
        return (Double(h), Double(s), Double(br))
    }
    return nil
}

private func hsbToHex(h: Double, s: Double, b: Double) -> String {
    let uiColor = UIColor(hue: CGFloat(h), saturation: CGFloat(s), brightness: CGFloat(b), alpha: 1.0)
    var r: CGFloat = 0, g: CGFloat = 0, bl: CGFloat = 0, a: CGFloat = 0
    uiColor.getRed(&r, green: &g, blue: &bl, alpha: &a)
    let ri = Int(round(r * 255.0))
    let gi = Int(round(g * 255.0))
    let bi = Int(round(bl * 255.0))
    return String(format: "%02X%02X%02X", max(0, min(255, ri)), max(0, min(255, gi)), max(0, min(255, bi)))
}

private extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted), radix: 16) ?? 0xEE8C8C
        self.init(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }
}