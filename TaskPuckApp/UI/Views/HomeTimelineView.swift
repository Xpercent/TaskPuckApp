import SwiftUI

public struct HomeTimelineView: View {
    @Environment(TaskEngine.self) private var engine
    @AppStorage(AppConstants.StorageKeys.appThemeHex) private var themeHex = AppConstants.Appearance.defaultTintHex
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var visibleWeekOffset = 0
    @State private var displayedDate = Calendar.current.startOfDay(for: Date())
    @State private var pendingDate: Date?
    @State private var transition: CardTransition?
    @State private var cardOffset: CGFloat = 0
    @State private var dragTranslation: CGFloat = 0

    private let weekOffsets = AppConstants.Timeline.weekOffsetRange
    private let calendar = DateUtils.calendar
    private let cardSpacing: CGFloat = 16

    public var body: some View {
        let _ = engine.dataVersion
        ZStack {
            AppConstants.Colors.backgroundGrey.ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. 日历与头部区域（整体上移，间距全面紧凑化）
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
                    .frame(height: 52) // 压缩周日历区域高度
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
                .padding(.top, 0) // 整体向上移动
                .padding(.bottom, 2) // 缩小日历与时间轴卡片的垂直间距

                // 2. 时间轴卡片区域（性能优化，120Hz 丝滑流畅）
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
                    VStack(spacing: 2) { // 缩小日历星期标题与号数的垂直间距
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

    private var threeCardTimeline: some View {
        GeometryReader { proxy in
            let cardWidth = proxy.size.width
            let slotWidth = cardWidth + cardSpacing
            let dates = cardDates

            HStack(spacing: cardSpacing) {
                timelineCard(for: dates.previous, width: cardWidth)
                timelineCard(for: dates.current, width: cardWidth)
                timelineCard(for: dates.next, width: cardWidth)
            }
            .offset(x: -slotWidth + transitionOffset(for: slotWidth))
            .simultaneousGesture(timelineDragGesture(slotWidth: slotWidth))
        }
        .clipped()
    }

    private var cardDates: (previous: Date, current: Date, next: Date) {
        guard let transition else {
            return (dayOffset(-1, from: displayedDate), displayedDate, dayOffset(1, from: displayedDate))
        }

        switch transition.direction {
        case .forward:
            return (dayOffset(-1, from: displayedDate), displayedDate, transition.destination)
        case .backward:
            return (transition.destination, displayedDate, dayOffset(1, from: displayedDate))
        }
    }

    private func timelineCard(for date: Date, width: CGFloat) -> some View {
        let dateString = DateUtils.string(from: date)
        return TimelineCardView(date: date, dateString: dateString)
            .frame(width: width)
            // A date-specific identity prevents an outgoing card from receiving incoming task content.
            .id(dateString)
    }

    private func timelineDragGesture(slotWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard transition == nil, abs(value.translation.width) > abs(value.translation.height) else { return }
                dragTranslation = value.translation.width
            }
            .onEnded { value in
                guard transition == nil else { return }
                let translation = value.translation.width
                guard abs(translation) > abs(value.translation.height), abs(translation) > slotWidth * 0.2 else {
                    withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                        dragTranslation = 0
                    }
                    return
                }
                let initialCardOffset = translation / slotWidth
                dragTranslation = 0
                requestDateSelection(
                    dayOffset(translation < 0 ? 1 : -1, from: displayedDate),
                    initialCardOffset: initialCardOffset
                )
            }
    }

    private func transitionOffset(for slotWidth: CGFloat) -> CGFloat {
        (transition == nil ? dragTranslation : cardOffset * slotWidth)
    }

    private func requestDateSelection(
        _ date: Date,
        updateEngine: Bool = true,
        initialCardOffset: CGFloat = 0
    ) {
        let normalizedDate = calendar.startOfDay(for: date)
        guard !calendar.isDate(normalizedDate, inSameDayAs: selectedDate) else { return }

        selectedDate = normalizedDate
        let targetOffset = calculateWeekOffset(for: normalizedDate)
        if visibleWeekOffset != targetOffset {
            visibleWeekOffset = targetOffset
        }
        if updateEngine {
            engine.selectDate(DateUtils.string(from: normalizedDate))
        }

        if transition != nil {
            // Keep the latest tap without replacing the data in the card currently leaving the screen.
            pendingDate = normalizedDate
            return
        }
        beginTransition(to: normalizedDate, initialCardOffset: initialCardOffset)
    }

    private func beginTransition(to destination: Date, initialCardOffset: CGFloat = 0) {
        guard !calendar.isDate(destination, inSameDayAs: displayedDate) else { return }

        let direction: CardTransition.Direction = destination > displayedDate ? .forward : .backward
        let nextTransition = CardTransition(destination: destination, direction: direction)
        transition = nextTransition
        cardOffset = initialCardOffset

        withAnimation(
            .smooth(duration: 0.3, extraBounce: 0),
            completionCriteria: .removed
        ) {
            cardOffset = direction == .forward ? -1 : 1
        } completion: {
            completeTransition(nextTransition)
        }
    }

    private func completeTransition(_ finishedTransition: CardTransition) {
        guard transition?.id == finishedTransition.id else { return }
        withTransaction(Transaction(animation: nil)) {
            displayedDate = finishedTransition.destination
            transition = nil
            cardOffset = 0
        }

        if let pendingDate {
            self.pendingDate = nil
            beginTransition(to: pendingDate)
        }
    }

    private func dayOffset(_ offset: Int, from date: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: date) ?? date
    }

    // 精确安全的周偏移量计算，避免跨年/跨月 weekOfYear 溢出 Bug
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

private struct CardTransition: Equatable {
    enum Direction: Equatable {
        case backward
        case forward
    }

    let id = UUID()
    let destination: Date
    let direction: Direction
}

// 独立抽离 TimelineCardView 并结合 .compositingGroup() 解决左右滑动卡顿
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
        .compositingGroup() // 开启 GPU 离屏渲染纹理缓存，大幅提升滑动帧率
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
