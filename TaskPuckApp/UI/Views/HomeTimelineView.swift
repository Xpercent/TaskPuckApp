import SwiftUI

public struct HomeTimelineView: View {
    @Environment(TaskEngine.self) private var engine
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var visibleWeekOffset = 0

    private let weekOffsets = Array(-260...260)
    private let calendar = DateUtils.calendar

    public var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.97).ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 4) {
                        Text(DateUtils.yearString(from: selectedDate))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.93, green: 0.55, blue: 0.55))
                        Text(DateUtils.monthDayString(from: selectedDate))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.2))
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
                    Color.white
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: -5)

                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.18))
                                .frame(width: 2)
                                .padding(.leading, 31)
                                .padding(.vertical, 20)

                            VStack(spacing: 28) {
                                let items = engine.getTaskStack(for: engine.selectedDateString)
                                ForEach(items) { item in
                                    InteractiveTimelineRow(item: item) {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                            engine.toggleTaskStatus(instance: item.instance)
                                        }
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                }
                            }
                        }
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
                            .foregroundStyle(isSelected ? .white : Color(red: 0.15, green: 0.15, blue: 0.2))
                            .frame(width: 32, height: 32)
                            .background(isSelected ? Color.black : Color.clear, in: Circle())
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
    let onToggle: () -> Void

    private var iconBgColor: Color {
        if item.task.iconSymbol == "alarm.fill" {
            return Color(red: 0.93, green: 0.55, blue: 0.55)
        } else if item.task.iconSymbol == "moon.fill" {
            return Color(red: 0.35, green: 0.50, blue: 0.65)
        } else {
            return Color(red: 0.93, green: 0.62, blue: 0.62)
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBgColor)
                    .frame(width: 44, height: 44)
                    .shadow(color: iconBgColor.opacity(0.3), radius: 6, x: 0, y: 3)

                Image(systemName: item.task.iconSymbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.leading, 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let placement = item.placement {
                        let duration = DateUtils.calculateDuration(startTime: placement.startTime, endTime: placement.endTime)
                        Text("\(placement.startTime) - \(placement.endTime) (\(duration)分钟)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.gray.opacity(0.8))
                    }

                    if item.task.iconSymbol == "alarm.fill" {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
                }

                Text(item.task.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.2))
            }

            Spacer()

            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(
                            item.instance.status == .done
                                ? Color(red: 0.93, green: 0.55, blue: 0.55)
                                : (item.task.iconSymbol == "moon.fill"
                                    ? Color(red: 0.35, green: 0.50, blue: 0.65)
                                    : Color(red: 0.93, green: 0.55, blue: 0.55)),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if item.instance.status == .done {
                        Circle()
                            .fill(Color(red: 0.93, green: 0.55, blue: 0.55))
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24)
        }
    }
}
