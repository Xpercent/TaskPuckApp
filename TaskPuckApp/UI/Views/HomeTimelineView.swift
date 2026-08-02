import SwiftUI

public struct HomeTimelineView: View {
    @Environment(TaskEngine.self) private var engine
    @State private var selectedDayIndex = 6 // 周六 1日

    private let dates = [
        (day: "周日", date: "26"),
        (day: "周一", date: "27"),
        (day: "周二", date: "28"),
        (day: "周三", date: "29"),
        (day: "周四", date: "30"),
        (day: "周五", date: "31"),
        (day: "周六", date: "1")
    ]

    public var body: some View {
        VStack(spacing: 0) {
            // Top Date Header
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 4) {
                    Text("2026")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.55))
                    Text("年 8月1日")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.55))
                }
                .padding(.horizontal, 24)

                // Date Picker Strip
                HStack(spacing: 0) {
                    ForEach(0..<dates.count, id: \.self) { index in
                        let isSelected = (index == selectedDayIndex)
                        VStack(spacing: 6) {
                            Text(dates[index].day)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.gray)
                            
                            Text(dates[index].date)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(isSelected ? .white : Color(red: 0.15, green: 0.15, blue: 0.2))
                                .frame(width: 30, height: 30)
                                .background(isSelected ? Color.black : Color.clear, in: Circle())
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            selectedDayIndex = index
                            let targetDateStr = index == 6 ? "2026-08-01" : String(format: "2026-07-%02d", 26 + index)
                            engine.selectDate(targetDateStr)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.top, 12)
            .padding(.bottom, 16)

            // Timeline Task Content Card Area
            ZStack {
                Color.white
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        let items = engine.getTaskStack(for: engine.selectedDateString)
                        
                        ZStack(alignment: .leading) {
                            // Timeline Connecting Line
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 2)
                                .padding(.leading, 31)
                                .padding(.vertical, 20)

                            VStack(spacing: 24) {
                                ForEach(items) { item in
                                    TimelineRowItem(item: item) {
                                        engine.toggleTaskStatus(instance: item.instance)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97))
    }
}

// MARK: - Subview: Timeline Row Item

struct TimelineRowItem: View {
    let item: DisplayTimelineItem
    let onToggle: () -> Void

    private var iconBackgroundColor: Color {
        if item.task.iconSymbol == "alarm.fill" {
            return Color(red: 0.95, green: 0.55, blue: 0.55)
        } else if item.task.iconSymbol == "moon.fill" {
            return Color(red: 0.35, green: 0.50, blue: 0.65)
        } else {
            return Color(red: 0.95, green: 0.6, blue: 0.6).opacity(0.7)
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon Bubble on Timeline
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: item.task.iconSymbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.leading, 10)

            // Task Detail & Time Row
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let placement = item.placement {
                        let duration = DateUtils.calculateDuration(startTime: placement.startTime, endTime: placement.endTime)
                        Text("\(placement.startTime) – \(placement.endTime) (\(duration)分钟)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.gray)
                    } else {
                        Text(item.task.defaultPlacement?.startTime ?? "全天")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.gray)
                    }

                    if item.task.iconSymbol == "alarm.fill" {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }

                Text(item.task.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
            }

            Spacer()

            // Completion Radio/Check Button
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(item.instance.status == .done ? Color(red: 0.95, green: 0.55, blue: 0.55) : (item.task.iconSymbol == "moon.fill" ? Color(red: 0.35, green: 0.50, blue: 0.65) : Color(red: 0.95, green: 0.55, blue: 0.55)), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if item.instance.status == .done {
                        Circle()
                            .fill(Color(red: 0.95, green: 0.55, blue: 0.55))
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.trailing, 24)
        }
    }
}