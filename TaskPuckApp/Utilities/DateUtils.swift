import Foundation

public enum DateUtils {
    public static var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.firstWeekday = 1
        return calendar
    }

    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()

    public static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    public static func string(from date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    public static func date(from string: String) -> Date? {
        return dateFormatter.date(from: string)
    }

    public static func todayString() -> String {
        return string(from: Date())
    }

    public static func startOfWeek(containing date: Date, addingWeeks weeks: Int = 0) -> Date {
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        return calendar.date(byAdding: .weekOfYear, value: weeks, to: start) ?? start
    }

    public static func yearString(from date: Date) -> String {
        String(calendar.component(.year, from: date))
    }

    public static func monthDayString(from date: Date) -> String {
        "\(calendar.component(.month, from: date))月\(calendar.component(.day, from: date))日"
    }

    public static func weekdayString(from date: Date) -> String {
        let symbols = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return symbols[calendar.component(.weekday, from: date) - 1]
    }

    public static func dayString(from date: Date) -> String {
        String(calendar.component(.day, from: date))
    }

    public static func accessibilityDateString(from date: Date) -> String {
        "\(yearString(from: date))年\(monthDayString(from: date))，\(weekdayString(from: date))"
    }

    public static func calculateEndTime(startTime: String, durationMinutes: Int) -> String {
        let parts = startTime.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return startTime }
        let totalStartMinutes = parts[0] * 60 + parts[1]
        let totalEndMinutes = (totalStartMinutes + durationMinutes) % (24 * 60)
        let endHours = totalEndMinutes / 60
        let endMins = totalEndMinutes % 60
        return String(format: "%02d:%02d", endHours, endMins)
    }

    public static func calculateDuration(startTime: String, endTime: String) -> Int {
        let startParts = startTime.split(separator: ":").compactMap { Int($0) }
        let endParts = endTime.split(separator: ":").compactMap { Int($0) }
        guard startParts.count == 2, endParts.count == 2 else { return 0 }
        let startMins = startParts[0] * 60 + startParts[1]
        let endMins = endParts[0] * 60 + endParts[1]
        let difference = endMins - startMins
        return difference >= 0 ? difference : difference + 24 * 60
    }

    public static func durationDisplayString(minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 { return "\(remainder)分钟" }
        if remainder == 0 { return "\(hours)小时" }
        return "\(hours)小时\(remainder)分钟"
    }
}
