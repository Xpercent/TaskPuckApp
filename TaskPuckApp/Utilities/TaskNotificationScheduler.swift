import Foundation
import UserNotifications

@MainActor
enum TaskNotificationScheduler {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func schedule(
        task: TaskEntity,
        instance: TaskInstanceEntity,
        startTime: String,
        durationMinutes: Int
    ) {
        guard task.notificationsEnabled,
              let fireDate = notificationDate(dateString: instance.currentDate, timeString: startTime),
              fireDate > Date() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = notificationBody(startTime: startTime, durationMinutes: durationMinutes)
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let request = UNNotificationRequest(
            identifier: identifier(for: instance),
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancel(for instance: TaskInstanceEntity) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: instance)])
    }

    static func cancel(for instances: [TaskInstanceEntity]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: instances.map { identifier(for: $0) }
        )
    }

    private static func identifier(for instance: TaskInstanceEntity) -> String {
        "task-notification-\(instance.id)"
    }

    private static func notificationDate(dateString: String, timeString: String) -> Date? {
        let values = timeString.split(separator: ":").compactMap { Int($0) }
        guard values.count == 2,
              let date = DateUtils.date(from: dateString) else {
            return nil
        }
        return Calendar.current.date(bySettingHour: values[0], minute: values[1], second: 0, of: date)
    }

    private static func notificationBody(startTime: String, durationMinutes: Int) -> String {
        guard durationMinutes > 0 else { return startTime }
        let endTime = DateUtils.calculateEndTime(startTime: startTime, durationMinutes: durationMinutes)
        return "\(startTime) - \(endTime) (\(durationTitle(for: durationMinutes)))"
    }

    private static func durationTitle(for minutes: Int) -> String {
        minutes < 60 ? "\(minutes)m" : (minutes % 60 == 0 ? "\(minutes / 60)h" : "\(minutes / 60)h \(minutes % 60)m")
    }
}
