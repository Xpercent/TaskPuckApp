import SwiftUI

public struct HomeTimelineView: View {
    @Environment(TaskEngine.self) private var engine
    @State private var selectedDayIndex = 6 // 默认选中周六 1日

    private let dates = [
        (day: "周日", date: "26", dateStr: "2026-07-26"),
        (day: "周一", date: "27", dateStr: "2026-07-27"),
        (day: "周二", date: "28", dateStr: "2026-07-28"),
        (day: "周三", date: "29", dateStr: "2026-07-29"),
        (day: "周四", date: "30", dateStr: "2026-07-30"),
        (day: "周五", date: "31", dateStr: "2026-07-31"),
        (day: "周六", date: "1",  dateStr: "2026-08-01")
    ]

    public var body: some View {
        ZStack {
            // 背景底色与动态弥散光斑（为 Liquid Glass 提供折射光源）
            Color(red: 0.96, green: 0.96, blue: 0.97).ignoresSafeArea()

            Circle()
                .fill(Color(red: 0.95, green: 0.7, blue: 0.7).opacity(0.25))
                .frame(width: 260, height: 260)
                .blur(radius: 50)
                .offset(x: -100, y: -250)

            VStack(spacing: 0) {
                // 顶部日期头与可左右滑动的日历 Strip
                VStack(alignment: .leading, spacing: 16) {
                    // 年月标题
                    HStack(spacing: 4) {
                        Text("2026")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.93, green: 0.55, blue: 0.55))
                        Text("年 8月1日")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 0.93, green: 0.55, blue: 0.55))
                    }
                    .padding(.horizontal, 24)

                    // 可左右滑动选择的日历栏
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<dates.count, id: \.self) { index in
                                let isSelected = (index == selectedDayIndex)
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedDayIndex = index
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    engine.selectDate(dates[index].dateStr)
                                }) {
                                    VStack(spacing: 8) {
                                        Text(dates[index].day)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color.gray)
                                        
                                        Text(dates[index].date)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(isSelected ? .white : Color(red: 0.15, green: 0.15, blue: 0.2))
                                            .frame(width: 32, height: 32)
                                            .background(isSelected ? Color.black : Color.clear, in: Circle())
                                    }
                                    .frame(width: 42)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 16)

                // 时间轴主要白色卡片区
                ZStack {
                    Color.white
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: -5)

                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .leading) {
                            // 连贯的时间轴灰色垂直虚线
                            Rectangle()
                                .fill(Color.gray.opacity(0.18))
                                .frame(width: 2)
                                .padding(.leading, 31)
                                .padding(.vertical, 20)

                            VStack(spacing: 28) {
                                let items = engine.getTaskStack(for: engine.selectedDateString)
                                ForEach(items) { item in
                                    InteractiveTimelineRow(item: item) {
                                        withAnimation(.spring(response: 0.2)) {
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
}

// 可点击交互打卡的时间轴单行 Item
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
            // 左侧图标圆圈
            ZStack {
                Circle()
                    .fill(iconBgColor)
                    .frame(width: 44, height: 44)
                    .shadow(color: iconBgColor.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Image(systemName: item.task.iconSymbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.leading, 10)

            // 任务详情
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let placement = item.placement {
                        let dur = DateUtils.calculateDuration(startTime: placement.startTime, endTime: placement.endTime)
                        Text("\(placement.startTime) – \(placement.endTime) (\(dur)分钟)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.gray.opacity(0.8))
                    }

                    if item.task.iconSymbol == "alarm.fill" {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }

                Text(item.task.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
            }

            Spacer()

            // 打卡状态圈按钮
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(
                            item.instance.status == .done ? Color(red: 0.93, green: 0.55, blue: 0.55) : (item.task.iconSymbol == "moon.fill" ? Color(red: 0.35, green: 0.50, blue: 0.65) : Color(red: 0.93, green: 0.55, blue: 0.55)),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if item.instance.status == .done {
                        Circle()
                            .fill(Color(red: 0.93, green: 0.55, blue: 0.55))
                            .frame(width: 24, height: 24)
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