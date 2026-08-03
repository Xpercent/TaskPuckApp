import SwiftUI

public struct HomeTimelineView: View {
    // 注入任务引擎，用于管理数据和业务逻辑
    @Environment(TaskEngine.self) private var engine
    // 当前选中的具体日期
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    // TabView 当前的周偏移量索引
    @State private var visibleWeekOffset = 0

    // 预生成的周偏移范围，支持前后滑动约5年
    private let weekOffsets = Array(-260...260)
    // 获取日历实例
    private let calendar = DateUtils.calendar

    public var body: some View {
        ZStack {
            // 背景色：浅灰蓝色
            Color(red: 0.96, green: 0.96, blue: 0.97).ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    // 顶部日期显示：年份（粉色）和月日（深色）
                    HStack(spacing: 4) {
                        Text(DateUtils.yearString(from: selectedDate))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.93, green: 0.55, blue: 0.55))
                        Text(DateUtils.monthDayString(from: selectedDate))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.2))
                    }
                    .padding(.horizontal, 24)

                    // 周视图滑动选择器
                    TabView(selection: $visibleWeekOffset) {
                        ForEach(weekOffsets, id: \.self) { offset in
                            weekPage(offset: offset)
                                .tag(offset)
                        }
                    }
                    .frame(height: 66)
                    .tabViewStyle(.page(indexDisplayMode: .never)) // 隐藏分页指示器
                    // 监听周偏移变化，联动更新选中日期并保持星期几不变
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

                // 下方白色卡片区域
                ZStack {
                    Color.white
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: -5)

                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .leading) {
                            // 【改进2】：时间轴向右移动5（31 -> 36）
                            Rectangle()
                                .fill(Color.gray.opacity(0.18))
                                .frame(width: 2)
                                .padding(.leading, 36)
                                .padding(.vertical, 20)

                            // 任务列表垂直排列
                            VStack(spacing: 28) {
                                let items = engine.getTaskStack(for: engine.selectedDateString)
                                ForEach(items) { item in
                                    InteractiveTimelineRow(item: item, selectedDate: selectedDate) {
                                        // 切换任务状态并触发弹簧动画
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                            engine.toggleTaskStatus(instance: item.instance)
                                        }
                                        // 触发中等强度触觉反馈
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                }
                            }
                        }
                        .padding(.top, 28)
                        .padding(.bottom, 120)
                    }
                }
                .ignoresSafeArea(edges: .bottom) // 底部延伸至屏幕边缘
            }
        }
    }

    // 生成单周的日期选择视图
    private func weekPage(offset: Int) -> some View {
        let start = DateUtils.startOfWeek(containing: Date(), addingWeeks: offset)
        return HStack(spacing: 12) {
            ForEach(0..<7, id: \.self) { dayOffset in
                let date = calendar.date(byAdding: .day, value: dayOffset, to: start) ?? start
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                Button {
                    // 点击日期：更新选中状态、触发轻微震动、通知引擎
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
    let selectedDate: Date
    let onToggle: () -> Void

    // 未到达时间时的灰色底色
    private let unreachedBgColor = Color(red: 0.90, green: 0.90, blue: 0.92)

    // 根据图标类型返回对应的主题背景色
    private var iconBgColor: Color {
        if item.task.iconSymbol == "alarm.fill" {
            return Color(red: 0.93, green: 0.55, blue: 0.55)
        } else if item.task.iconSymbol == "moon.fill" {
            return Color(red: 0.35, green: 0.50, blue: 0.65)
        } else {
            return Color(red: 0.93, green: 0.62, blue: 0.62)
        }
    }

    // 【改进4】：根据当前时间计算任务进度 (0.0 ~ 1.0)
    private var progress: Double {
        guard let placement = item.placement else { return 0.0 }

        let calendar = Calendar.current
        let now = Date()

        // 拼接具体起止时间 Date 对象
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

    // 生成具有软渐变过度（Soft Edge Transition）的 LinearGradient
    private func createSmoothGradient(reachedColor: Color, unreachedColor: Color) -> LinearGradient {
        let p = progress
        if p <= 0 {
            return LinearGradient(colors: [unreachedColor], startPoint: .top, endPoint: .bottom)
        } else if p >= 1 {
            return LinearGradient(colors: [reachedColor], startPoint: .top, endPoint: .bottom)
        }

        // 柔和过度宽度比例
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

        HStack(alignment: .center, spacing: 16) {
            // 【改进1 & 2 & 4】：任务图标圆底增大1/3 (44 -> 58.67pt)，字号由20提升至24pt，带渐变进度
            ZStack {
                // 1. 圆形背景底座 (包含渐变过度)
                Circle()
                    .fill(createSmoothGradient(reachedColor: iconBgColor, unreachedColor: unreachedBgColor))
                    .frame(width: 58.67, height: 58.67)
                    .shadow(color: iconBgColor.opacity(progress > 0 ? 0.25 : 0.05), radius: 6, x: 0, y: 3)

                // 2. 渐变图标（已过时间显示白色，未过时间显示主题色）
                Image(systemName: item.task.iconSymbol)
                    .font(.system(size: 24, weight: .bold)) // 增大一个字号
                    .foregroundStyle(createSmoothGradient(reachedColor: .white, unreachedColor: iconBgColor))
            }
            // 调整 Leading 边距使圆心精准对齐 x=36 的时间线
            .padding(.leading, 7.67)

            // 中间：时间信息与标题
            VStack(alignment: .leading, spacing: 4) {
                if let placement = item.placement {
                    let duration = DateUtils.calculateDuration(startTime: placement.startTime, endTime: placement.endTime)
                    Text("\(placement.startTime) - \(placement.endTime) (\(duration)分钟)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.gray.opacity(0.8))
                }

                // 【改进5】：打勾后任务名变灰，并由左向右滑过一条灰线 strike-through 动画
                Text(item.task.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isDone ? Color.gray.opacity(0.5) : Color(red: 0.15, green: 0.15, blue: 0.2))
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: isDone ? geo.size.width : 0, height: 2)
                                .frame(maxHeight: .infinity, alignment: .center)
                        }
                    }
            }

            Spacer()

            // 【改进3】：完成状态切换按钮缩小一点（24->20pt），外圈圆环加粗（2->3pt），右侧位置保持不变
            Button(action: onToggle) {
                ZStack {
                    // 外圈圆环
                    Circle()
                        .stroke(
                            isDone
                                ? Color(red: 0.93, green: 0.55, blue: 0.55)
                                : (item.task.iconSymbol == "moon.fill"
                                    ? Color(red: 0.35, green: 0.50, blue: 0.65)
                                    : Color(red: 0.93, green: 0.55, blue: 0.55)),
                            lineWidth: 3 // 加粗外圈
                        )
                        .frame(width: 20, height: 20) // 缩小按钮

                    // 已完成状态：填充背景并显示对勾
                    if isDone {
                        Circle()
                            .fill(Color(red: 0.93, green: 0.55, blue: 0.55))
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24) // 保持不变
        }
    }

    // 辅助解析 "HH:mm" 字符串并与基准日期结合
    private func dateBySettingTimeString(_ timeString: String, on baseDate: Date) -> Date? {
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }

        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)
    }
}