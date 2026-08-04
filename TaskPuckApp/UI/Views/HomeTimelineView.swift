import SwiftUI

public struct HomeTimelineView: View {
    @Environment(TaskEngine.self) private var engine
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var visibleWeekOffset = 0

    private let weekOffsets = AppConstants.Timeline.weekOffsetRange
    private let calendar = DateUtils.calendar

    public var body: some View {
        ZStack {
            AppConstants.Colors.backgroundGrey.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 4) {
                        Text(DateUtils.yearString(from: selectedDate))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppConstants.Colors.yearTextPink)
                        Text(DateUtils.monthDayString(from: selectedDate))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppConstants.Colors.primaryTextDark)
                    }
                    .padding(.horizontal, 24)

                    TabView(selection: $visibleWeekOffset) {
                        ForEach(weekOffsets, id: \.self) { offset in
                            weekPage(offset: offset)
                                .tag(offset)
                        }
                    }
                    .frame(height: 66)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: visibleWeekOffset) { _, newOffset in
                        let selectedWeekday = calendar.component(.weekday, from: selectedDate)
                        let targetStart = DateUtils.startOfWeek(
                            containing: Date(),
                            addingWeeks: newOffset
                        )
                        selectedDate = calendar.date(
                            byAdding: .day,
                            value: selectedWeekday - 1,
                            to: targetStart
                        ) ?? targetStart
                        engine.selectDate(DateUtils.string(from: selectedDate))
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 16)

                ZStack {
                    // 使用动态卡片背景替代硬编码 Color.white
                    AppConstants.Colors.cardBackground
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: -5)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 28) {
                            let items = engine.getTaskStack(for: engine.selectedDateString)
                            ForEach(items) { item in
                                InteractiveTimelineRow(item: item, selectedDate: selectedDate) {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        engine.toggleTaskStatus(instance: item.instance)
                                    }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .padding(.bottom, 120)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedDate = date
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    engine.selectDate(DateUtils.string(from: date))
                } label: {
                    VStack(spacing: 8) {
                        Text(DateUtils.weekdayString(from: date))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(DateUtils.dayString(from: date))
                            .font(.system(size: 16, weight: .bold))
                            // 选中状态采用系统主文字色作为背景，系统底色作为前景色，实现双向自动反转
                            .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : AppConstants.Colors.primaryTextDark)
                            .frame(width: 32, height: 32)
                            .background(isSelected ? Color.primary : Color.clear, in: Circle())
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
        // 修正：item.instance 为非可选类型，移除问号 ?
        let isDone = item.instance.status == .done

        HStack(spacing: 16) {
            ZStack(alignment: .center) {
                // 使用系统分割线颜色替代 Color.gray.opacity
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
                    let duration = DateUtils.calculateDuration(startTime: placement.startTime, endTime: placement.endTime)
                    Text("\(placement.startTime) - \(placement.endTime) (\(duration)分钟)")
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