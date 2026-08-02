import Foundation
import SwiftData

// MARK: - Enums & Supporting Value Types

public enum Priority: String, Codable, CaseIterable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case urgent = "URGENT"

    public var title: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .urgent: return "紧急"
        }
    }
}

public enum InstanceStatus: String, Codable {
    case todo = "TODO"
    case done = "DONE"
    case missed = "MISSED"
    case moved = "MOVED"
    case cancelled = "CANCELLED"
}

public enum Weekday: String, Codable, CaseIterable {
    case mon = "MON", tue = "TUE", wed = "WED", thu = "THU", fri = "FRI", sat = "SAT", sun = "SUN"
}

public enum RecurrenceRule: Codable, Equatable {
    case daily
    case weekly(weekdays: [Weekday])
    case once(date: String) // YYYY-MM-DD
    case dateRange(start: String, end: String, autoArchive: Bool?)

    public var title: String {
        switch self {
        case .once: return "仅一次"
        case .daily: return "每日"
        case .weekly: return "每周"
        case .dateRange: return "每月"
        }
    }
}

public struct DefaultPlacement: Codable, Equatable {
    public var startTime: String // "HH:mm"
    public var duration: Int     // 分钟

    public init(startTime: String, duration: Int) {
        self.startTime = startTime
        self.duration = duration
    }
}

// MARK: - SwiftData Persistent Models

@Model
public final class TaskEntity {
    @Attribute(.unique) public var id: String
    public var title: String
    public var iconSymbol: String
    public var taskDescription: String?
    public var priorityRaw: String
    public var recurrenceRulesData: Data
    public var defaultPlacementData: Data?
    public var isArchived: Bool
    public var createdAt: Date

    public var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    public var recurrenceRules: [RecurrenceRule] {
        get { (try? JSONDecoder().decode([RecurrenceRule].self, from: recurrenceRulesData)) ?? [] }
        set { recurrenceRulesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    public var defaultPlacement: DefaultPlacement? {
        get {
            guard let defaultPlacementData else { return nil }
            return try? JSONDecoder().decode(DefaultPlacement.self, from: defaultPlacementData)
        }
        set {
            if let newValue {
                defaultPlacementData = try? JSONEncoder().encode(newValue)
            } else {
                defaultPlacementData = nil
            }
        }
    }

    public init(
        id: String = UUID().uuidString,
        title: String,
        iconSymbol: String = "at",
        taskDescription: String? = nil,
        priority: Priority = .medium,
        recurrenceRules: [RecurrenceRule] = [.daily],
        defaultPlacement: DefaultPlacement? = nil,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.iconSymbol = iconSymbol
        self.taskDescription = taskDescription
        self.priorityRaw = priority.rawValue
        self.recurrenceRulesData = (try? JSONEncoder().encode(recurrenceRules)) ?? Data()
        if let defaultPlacement {
            self.defaultPlacementData = try? JSONEncoder().encode(defaultPlacement)
        }
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}

@Model
public final class TaskInstanceEntity {
    @Attribute(.unique) public var id: String
    public var taskId: String
    public var originalDate: String // YYYY-MM-DD
    public var currentDate: String  // YYYY-MM-DD
    public var statusRaw: String
    public var createdAt: Date

    public var status: InstanceStatus {
        get { InstanceStatus(rawValue: statusRaw) ?? .todo }
        set { statusRaw = newValue.rawValue }
    }

    public init(
        id: String = UUID().uuidString,
        taskId: String,
        originalDate: String,
        currentDate: String,
        status: InstanceStatus = .todo,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.originalDate = originalDate
        self.currentDate = currentDate
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
    }
}

@Model
public final class TimelinePlacementEntity {
    @Attribute(.unique) public var id: String
    public var instanceId: String
    public var startTime: String // "HH:mm"
    public var endTime: String   // "HH:mm"

    public init(id: String = UUID().uuidString, instanceId: String, startTime: String, endTime: String) {
        self.id = id
        self.instanceId = instanceId
        self.startTime = startTime
        self.endTime = endTime
    }
}

public struct UserProfile: Codable {
    public var id: String
    public var name: String
    public var avatarSymbol: String
    public var info: String
}