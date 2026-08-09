import SwiftUI

public struct HomeTimelineView: View {
    @Environment(TaskEngine.self) private var engine
    @AppStorage(AppConstants.StorageKeys.appThemeHex) private var themeHex = AppConstants.Appearance.defaultTintHex
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var visibleWeekOffset = 0
    @State private var displayedDate = Calendar.current.startOfDay(for: Date())

    private let weekOffsets = AppConstants.Timeline.weekOffsetRange
    private let calendar = DateUtils.calendar
    private let cardPadding: CGFloat = 8

    public var body: some View {
        let _ = engine.dataVersion
        ZStack {
            AppConstants.Colors.backgroundGrey.ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. 日历与头部区域
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(DateUtils.yearString(from: selectedDate))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: themeHex))
                        Text(DateUtils.monthDayString(from: selectedDate))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(AppConstants.Colors.primaryTextDark)
                    }
                    .padding(.horizontal, 24)

                    TabView(selection: $visibleWeekOffset) {
                        ForEach(weekOffsets, id: \.self) { offset in
                            weekPage(offset: offset)
                                .tag(offset)
                        }
                    }
                    .frame(height: 52)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: visibleWeekOffset) { _, newOffset in
                        let currentWeekOfSelected = DateUtils.startOfWeek(containing: Date(), addingWeeks: newOffset)
                        let selectedWeekday = calendar.component(.weekday, from: selectedDate)
                        let targetDate = calendar.date(byAdding: .day, value: selectedWeekday - 1, to: currentWeekOfSelected) ?? currentWeekOfSelected
                        
                        if !calendar.isDate(targetDate, inSameDayAs: selectedDate) {
                            requestDateSelection(targetDate)
                        }
                    }
                }
                .padding(.top, 0)
                .padding(.bottom, 2)

                // 2. 原生 TabView 分页时间轴卡片区域（拥有原生手势方向锁与 120Hz 丝滑物理滚轴）
                threeCardTimeline
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .onChange(of: engine.selectedDateString) { _, dateString in
            synchronizeTimelineDate(with: dateString)
        }
        .onAppear {
            synchronizeTimelineDate(with: engine.selectedDateString)
        }
    }

    private func weekPage(offset: Int) -> some View {
        let start = DateUtils.startOfWeek(containing: Date(), addingWeeks: offset)
        return HStack(spacing: 12) {
            ForEach(0..<7, id: \.self) { dayOffset in
                let date = calendar.date(byAdding: .day, value: dayOffset, to: start) ?? start
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                Button {
                    selectTimelineDate(date)
                } label: {
                    VStack(spacing: 2) {
                        Text(DateUtils.weekdayString(from: date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(DateUtils.dayString(from: date))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : AppConstants.Colors.primaryTextDark)
                            .frame(width: 30, height: 30)
                            .background(isSelected ? Color(hex: themeHex) : Color.clear, in: Circle())
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(DateUtils.accessibilityDateString(from: date))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 20)
    }

    private func selectTimelineDate(_ date: Date) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        requestDateSelection(date)
    }

    private func synchronizeTimelineDate(with dateString: String) {
        guard let date = dateFromFormattedString(dateString),
              !calendar.isDate(date, inSameDayAs: selectedDate) else {
            return
        }
        requestDateSelection(date, updateEngine: false)
    }

    // 使用原生 TabView(.page) 替代 HStack + DragGesture
    private var threeCardTimeline: some View {
        let dates = cardDates

        return TabView(selection: Binding(
            get: { dates.current },
            set: { newDate in
                if !calendar.isDate(newDate, inSameDayAs: displayedDate) {
                    requestDateSelection(newDate, isUserSwipe: true)
                }
            }
        )) {
            timelineCard(for: dates.previous)
                .tag(dates.previous)

            timelineCard(for: dates.current)
                .tag(dates.current)

            timelineCard(for: dates.next)
                .tag(dates.next)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var cardDates: (previous: Date, current: Date, next: Date) {
        let current = calendar.startOfDay(for: displayedDate)
        return (dayOffset(-1, from: current), current, dayOffset(1, from: current))
    }

    private func timelineCard(for date: Date) -> some View {
        let dateString = DateUtils.string(from: date)
        return TimelineCardView(date: date, dateString: dateString)
            .padding(.horizontal, cardPadding)
            .id(dateString)
    }

    private func requestDateSelection(
        _ date: Date,
        updateEngine: Bool = true,
        isUserSwipe: Bool = false
    ) {
        let normalizedDate = calendar.startOfDay(for: date)
        
        // 当选择的日期完全无变化时跳过
        if calendar.isDate(normalizedDate, inSameDayAs: selectedDate) && calendar.isDate(normalizedDate, inSameDayAs: displayedDate) {
            return
        }

        selectedDate = normalizedDate
        let targetOffset = calculateWeekOffset(for: normalizedDate)
        if visibleWeekOffset != targetOffset {
            visibleWeekOffset = targetOffset
        }
        if updateEngine {
            engine.selectDate(DateUtils.string(from: normalizedDate))
        }

        if isUserSwipe {
            // 手势翻页：TabView 已经完成视滑过渡，无缝静默更新 3 卡片基准
            withTransaction(Transaction(animation: nil)) {
                displayedDate = normalizedDate
            }
        } else {
            // 顶部日历点击：动画平滑过渡切换卡片
            withAnimation(.smooth(duration: 0.25, extraBounce: 0)) {
                displayedDate = normalizedDate
            }
        }
    }

    private func dayOffset(_ offset: Int, from date: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: date) ?? date
    }

    private func calculateWeekOffset(for date: Date) -> Int {
        let currentWeek = DateUtils.startOfWeek(containing: Date())
        let targetWeek = DateUtils.startOfWeek(containing: date)
        let days = calendar.dateComponents([.day], from: currentWeek, to: targetWeek).day ?? 0
        return Int(round(Double(days) / 7.0))
    }

    private func dateFromFormattedString(_ string: String) -> Date? {
        let parts = string.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }
}

// 独立的 TimelineCardView 结合内部 ScrollView
struct TimelineCardView: View {
    let date: Date
    let dateString: String
    @Environment(TaskEngine.self) private var engine

    var body: some View {
        let _ = engine.dataVersion
        ZStack {
            AppConstants.Colors.cardBackground
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: -4)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    let items = engine.getTaskStack(for: dateString)
                    ForEach(items) { item in
                        InteractiveTimelineRow(item: item, selectedDate: date) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                engine.toggleTaskStatus(instance: item.instance)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .contentShape(Rectangle())
        .ignoresSafeArea(edges: .bottom)
        .compositingGroup()
    }
}

struct InteractiveTimelineRow: View {
    let item: DisplayTimelineItem
    let selectedDate: Date
    let onToggle: () -> Void

    private var iconBgColor: Color {
        Color(hex: item.task.tintHex)
    }

    private var progress: Double {
        guard let placement = item.placement else { return 0.0 }

        let now = Date()
        guard let startTime = dateBySettingTimeString(placement.startTime, on: selectedDate),
              let endTime = dateBySettingTimeString(placement.endTime, on: selectedDate) else {
            return 0.0
        }

        if now <= startTime { return 0.0 }
        if now >= endTime { return 1.0 }

        let totalDuration = endTime.timeIntervalSince(startTime)
        guard totalDuration > 0 else { return 0.0 }

        let elapsed = now.timeIntervalSince(startTime)
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }

    private func createSmoothGradient(reachedColor: Color, unreachedColor: Color) -> LinearGradient {
        let p = progress
        if p <= 0 {
            return LinearGradient(colors: [unreachedColor], startPoint: .top, endPoint: .bottom)
        } else if p >= 1 {
            return LinearGradient(colors: [reachedColor], startPoint: .top, endPoint: .bottom)
        }

        let blendRange = 0.08
        let stop1 = max(0.0, p - blendRange)
        let stop2 = min(1.0, p + blendRange)

        return LinearGradient(
            stops: [
                .init(color: reachedColor, location: 0),
                .init(color: reachedColor, location: stop1),
                .init(color: unreachedColor, location: stop2),
                .init(color: unreachedColor, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        let isDone = item.instance.status == .done

        HStack(spacing: 16) {
            ZStack(alignment: .center) {
                Rectangle()
                    .fill(Color(uiColor: .separator))
                    .frame(width: 2)
                    .padding(.vertical, -14)

                Circle()
                    .fill(createSmoothGradient(reachedColor: iconBgColor, unreachedColor: AppConstants.Colors.unreachedBg))
                    .frame(width: 58.67, height: 58.67)
                    .shadow(color: iconBgColor.opacity(progress > 0 ? 0.25 : 0.05), radius: 6, x: 0, y: 3)

                Image(systemName: item.task.iconSymbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(createSmoothGradient(reachedColor: .white, unreachedColor: iconBgColor))
            }
            .frame(width: 58.67)

            VStack(alignment: .leading, spacing: 4) {
                if let placement = item.placement {
                    let duration = item.task.defaultPlacement?.duration
                        ?? DateUtils.calculateDuration(startTime: placement.startTime, endTime: placement.endTime)
                    Text(duration > 0
                        ? "\(placement.startTime) - \(placement.endTime) (\(DateUtils.durationDisplayString(minutes: duration)))"
                        : placement.startTime)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Text(item.task.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isDone ? Color.secondary.opacity(0.6) : AppConstants.Colors.primaryTextDark)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color.secondary.opacity(0.6))
                                .frame(width: isDone ? geo.size.width : 0, height: 2)
                                .frame(maxHeight: .infinity, alignment: .center)
                                .animation(.easeInOut(duration: 0.35), value: isDone)
                        }
                    }
            }

            Spacer(minLength: 8)

            TaskStatusCheckbox(
                isDone: isDone,
                tintColor: iconBgColor,
                mode: .standard,
                onToggle: onToggle
            )
            .padding(.trailing, 4)
        }
    }

    private func dateBySettingTimeString(_ timeString: String, on baseDate: Date) -> Date? {
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }

        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)
    }
}