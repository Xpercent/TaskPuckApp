import Foundation

public enum DateUtils {
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
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
        guard startParts.count == 2, endParts.count == 2 else { return 15 }
        let startMins = startParts[0] * 60 + startParts[1]
        let endMins = endParts[0] * 60 + endParts[1]
        return max(15, endMins - startMins)
    }
}