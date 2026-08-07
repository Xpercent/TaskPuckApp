import SwiftUI

public struct HomeTimelineView: View {
    @Environment(TaskEngine.self) private var engine
    @AppStorage(AppConstants.StorageKeys.appThemeHex) private var themeHex = AppConstants.Appearance.defaultTintHex
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var visibleWeekOffset = 0
    @State private var scrollPositionDateString: String? = DateUtils.string(from: Calendar.current.startOfDay(for: Date()))

    private let weekOffsets = AppConstants.Timeline.weekOffsetRange
    private let dayOffsets = -180...180
    private let calendar = DateUtils.calendar
    private let baseDate = DateUtils.calendar.startOfDay(for: Date())

    public var body: some View {
        let _ = engine.dataVersion
        ZStack {
            AppConstants.Colors.backgroundGrey.ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. 日历与头部区域（整体向上移动，紧凑排布）
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
                    .frame(height: 50)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: visibleWeekOffset) { _, newOffset in
                        let currentWeekOfSelected = DateUtils.startOfWeek(containing: Date(), addingWeeks: newOffset)
                        let selectedWeekday = calendar.component(.weekday, from: selectedDate)
                        let targetDate = calendar.date(byAdding: .day, value: selectedWeekday - 1, to: currentWeekOfSelected) ?? currentWeekOfSelected
                        
                        if !calendar.isDate(targetDate, inSameDayAs: selectedDate) {
                            selectedDate = targetDate
                            let dateString = DateUtils.string(from: targetDate)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                scrollPositionDateString = dateString
                            }
                            engine.selectDate(dateString)
                        }
                    }
                }
                .padding(.top, 0)
                .padding(.bottom, 2)

                // 2. 时间轴卡片区域（100%屏宽、卡片间距、平滑无卡顿）
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(dayOffsets, id: \.self) { offset in
                            let cardDate = calendar.date(byAdding: .day, value: offset, to: baseDate) ?? baseDate
                            let cardDateString = DateUtils.string(from: cardDate)

                            TimelineCardView(date: cardDate, dateString: cardDateString)
                                .containerRelativeFrame(.horizontal)
                                .id(cardDateString)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $scrollPositionDateString)
                .scrollTargetBehavior(.viewAligned)
                .onChange(of: scrollPositionDateString) { _, newDateString in
                    guard let newDateString, newDateString != DateUtils.string(from: selectedDate) else { return }
                    if let newDate = dateFromFormattedString(newDateString) {
                        selectedDate = newDate
                        let currentWeek = DateUtils.startOfWeek(containing: Date())
                        visibleWeekOffset = calendar.dateComponents([.weekOfYear], from: currentWeek, to: DateUtils.startOfWeek(containing: newDate)).weekOfYear ?? 0
                        engine.selectDate(newDateString)
                    }
                }
            }
        }
        .onAppear {
            if scrollPositionDateString == nil {
                scrollPositionDateString = DateUtils.string(from: selectedDate)
            }
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
                    VStack(spacing: 2) { // 缩小星期与号数的垂直间距 (8 -> 2)
                        Text(DateUtils.weekdayString(from: date))
                            .font(.system(size: 12, weight: .medium))
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
        let dateString = DateUtils.string(from: date)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedDate = date
            scrollPositionDateString = dateString
        }
        let currentWeek = DateUtils.startOfWeek(containing: Date())
        visibleWeekOffset = calendar.dateComponents([.weekOfYear], from: currentWeek, to: DateUtils.startOfWeek(containing: date)).weekOfYear ?? 0
        engine.selectDate(dateString)
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

// MARK: - 卡片独立视图（解决滑动卡顿）
struct TimelineCardView: View {
    let date: Date
    let dateString: String
    @Environment(TaskEngine.self) private var engine

    var body: some View {
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
    }
}

// MARK: - 交互行视图（性能优化的 Task 行）
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

    @ViewBuilder
    private var iconBackgroundShape: some View {
        let p = progress
        if p <= 0 {
            Circle().fill(AppConstants.Colors.unreachedBg)
        } else if p >= 1 {
            Circle().fill(iconBgColor)
        } else {
            Circle().fill(createSmoothGradient(reachedColor: iconBgColor, unreachedColor: AppConstants.Colors.unreachedBg, p: p))
        }
    }

    @ViewBuilder
    private var iconForegroundStyle: AnyShapeStyle {
        let p = progress
        if p <= 0 {
            AnyShapeStyle(iconBgColor)
        } else if p >= 1 {
            AnyShapeStyle(Color.white)
        } else {
            AnyShapeStyle(createSmoothGradient(reachedColor: .white, unreachedColor: iconBgColor, p: p))
        }
    }

    private func createSmoothGradient(reachedColor: Color, unreachedColor: Color, p: Double) -> LinearGradient {
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

                iconBackgroundShape
                    .frame(width: 58.67, height: 58.67)
                    .shadow(color: iconBgColor.opacity(progress > 0 ? 0.2 : 0.03), radius: 5, x: 0, y: 2)

                Image(systemName: item.task.iconSymbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(iconForegroundStyle)
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
                    .strikethrough(isDone, color: Color.secondary.opacity(0.6))
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