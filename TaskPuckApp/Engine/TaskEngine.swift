import Foundation
import SwiftUI
import SwiftData

public struct DisplayTimelineItem: Identifiable, Equatable {
    public var id: String { instance.id }
    public var task: TaskEntity
    public var instance: TaskInstanceEntity
    public var placement: TimelinePlacementEntity?
}

public struct TaskOverviewStats: Equatable {
    public var today: Int = 0
    public var planned: Int = 0
    public var all: Int = 0
    public var highPriority: Int = 0
    public var urgent: Int = 0
    public var completed: Int = 0
}

@Observable
@MainActor
public final class TaskEngine {
    private var modelContext: ModelContext
    public var selectedDateString: String
    public var isReadOnly: Bool = false
    public var toastMessage: String?

    public init(modelContext: ModelContext, initialDate: String = DateUtils.todayString()) {
        self.modelContext = modelContext
        self.selectedDateString = initialDate
        self.updateTemporalSafetyState()
    }

    // MARK: - Temporal Safety Guard

    public func selectDate(_ dateString: String) {
        self.selectedDateString = dateString
        self.updateTemporalSafetyState()
        self.ensureInstances(for: dateString)
        if dateString == DateUtils.todayString() {
            self.autoRollOverdueTasks()
        }
    }

    private func updateTemporalSafetyState() {
        let today = DateUtils.todayString()
        self.isReadOnly = selectedDateString < today
    }

    // MARK: - Engine Core 1: Dynamic Lazy Generation

    public func ensureInstances(for targetDate: String) {
        let taskDescriptor = FetchDescriptor<TaskEntity>(predicate: #Predicate { !$0.isArchived })
        guard let tasks = try? modelContext.fetch(taskDescriptor) else { return }

        let targetDateObj = DateUtils.date(from: targetDate) ?? Date()
        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: targetDateObj) // 1 = Sun, 2 = Mon ...

        for task in tasks {
            let taskId = task.id
            let instanceDescriptor = FetchDescriptor<TaskInstanceEntity>(
                predicate: #Predicate { $0.taskId == taskId && $0.currentDate == targetDate }
            )
            let existing = (try? modelContext.fetch(instanceDescriptor)) ?? []

            if existing.isEmpty && matchesRecurrence(rules: task.recurrenceRules, targetDate: targetDate, weekdayIndex: weekdayIndex) {
                let newInstance = TaskInstanceEntity(
                    taskId: task.id,
                    originalDate: targetDate,
                    currentDate: targetDate,
                    status: .todo
                )
                modelContext.insert(newInstance)

                // Default timeline placement if defined
                if let defaultPlacement = task.defaultPlacement {
                    let endTime = DateUtils.calculateEndTime(startTime: defaultPlacement.startTime, durationMinutes: defaultPlacement.duration)
                    let placement = TimelinePlacementEntity(instanceId: newInstance.id, startTime: defaultPlacement.startTime, endTime: endTime)
                    modelContext.insert(placement)
                }
            }
        }
        try? modelContext.save()
    }

    private func matchesRecurrence(rules: [RecurrenceRule], targetDate: String, weekdayIndex: Int) -> Bool {
        for rule in rules {
            switch rule {
            case .daily: return true
            case .once(let date): if date == targetDate { return true }
            case .weekly(let weekdays):
                if weekdays.contains(weekday(for: weekdayIndex)) { return true }
            case .monthly(let day):
                let targetDateObject = DateUtils.date(from: targetDate) ?? Date()
                if DateUtils.calendar.component(.day, from: targetDateObject) == day { return true }
            case .dateRange(let start, let end, _):
                if targetDate >= start && targetDate <= end { return true }
            }
        }
        return rules.isEmpty
    }

    private func weekday(for calendarWeekday: Int) -> Weekday {
        switch calendarWeekday {
        case 1: .sun
        case 2: .mon
        case 3: .tue
        case 4: .wed
        case 5: .thu
        case 6: .fri
        default: .sat
        }
    }

    // MARK: - Engine Core 2: Auto Roll Overdue Tasks

    public func autoRollOverdueTasks() {
        let today = DateUtils.todayString()
        let instanceDescriptor = FetchDescriptor<TaskInstanceEntity>(
            predicate: #Predicate { $0.currentDate < today && $0.statusRaw == "TODO" }
        )
        guard let overdueInstances = try? modelContext.fetch(instanceDescriptor) else { return }

        for instance in overdueInstances {
            instance.currentDate = today // Maintain originalDate, move currentDate to Today
        }
        try? modelContext.save()
    }

    // MARK: - Engine Core 3: Task Stack Sorting Matrix (4-Level Order)

    public func getTaskStack(for targetDate: String) -> [DisplayTimelineItem] {
        let instanceDescriptor = FetchDescriptor<TaskInstanceEntity>(
            predicate: #Predicate { $0.currentDate == targetDate }
        )
        guard let instances = try? modelContext.fetch(instanceDescriptor) else { return [] }

        var displayItems: [DisplayTimelineItem] = []

        for instance in instances {
            let taskId = instance.taskId
            let taskDescriptor = FetchDescriptor<TaskEntity>(predicate: #Predicate { $0.id == taskId })
            guard let task = (try? modelContext.fetch(taskDescriptor))?.first else { continue }

            let instanceId = instance.id
            let placementDescriptor = FetchDescriptor<TimelinePlacementEntity>(predicate: #Predicate { $0.instanceId == instanceId })
            let placement = (try? modelContext.fetch(placementDescriptor))?.first

            displayItems.append(DisplayTimelineItem(task: task, instance: instance, placement: placement))
        }

        // Sort timeline placed items chronologically
        displayItems.sort { (a, b) -> Bool in
            let timeA = a.placement?.startTime ?? "99:99"
            let timeB = b.placement?.startTime ?? "99:99"
            return timeA < timeB
        }

        return displayItems
    }

    public func overviewStats(for targetDate: String = DateUtils.todayString()) -> TaskOverviewStats {
        let taskDescriptor = FetchDescriptor<TaskEntity>(predicate: #Predicate { !$0.isArchived })
        let tasks = (try? modelContext.fetch(taskDescriptor)) ?? []
        let taskByID = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })

        let instanceDescriptor = FetchDescriptor<TaskInstanceEntity>()
        let instances = (try? modelContext.fetch(instanceDescriptor)) ?? []
        let validInstances = instances.filter { taskByID[$0.taskId] != nil && $0.status != .cancelled }

        return TaskOverviewStats(
            today: validInstances.filter { $0.currentDate == targetDate }.count,
            planned: tasks.filter { $0.defaultPlacement != nil }.count,
            all: tasks.count,
            highPriority: tasks.filter { $0.priority == .high || $0.priority == .urgent }.count,
            urgent: tasks.filter { $0.priority == .urgent }.count,
            completed: validInstances.filter { $0.status == .done }.count
        )
    }

    // MARK: - Actions

    public func toggleTaskStatus(instance: TaskInstanceEntity) {
        if isReadOnly {
            self.toastMessage = "历史排期不可篡改"
            return
        }
        instance.status = (instance.status == .done) ? .todo : .done
        try? modelContext.save()
    }

    public func createNewTask(
        title: String,
        durationMinutes: Int,
        recurrence: RecurrenceRule,
        startTime: String? = nil,
        initialStatus: InstanceStatus = .todo
    ) {
        if isReadOnly {
            self.toastMessage = "历史排期不可篡改"
            return
        }

        let defaultPlacement = startTime != nil ? DefaultPlacement(startTime: startTime!, duration: durationMinutes) : nil
        let newTask = TaskEntity(
            title: title,
            iconSymbol: "at",
            priority: .urgent,
            recurrenceRules: [recurrence],
            defaultPlacement: defaultPlacement
        )
        modelContext.insert(newTask)

        let newInstance = TaskInstanceEntity(
            taskId: newTask.id,
            originalDate: selectedDateString,
            currentDate: selectedDateString,
            status: initialStatus
        )
        modelContext.insert(newInstance)

        if let startTime {
            let endTime = DateUtils.calculateEndTime(startTime: startTime, durationMinutes: durationMinutes)
            let placement = TimelinePlacementEntity(instanceId: newInstance.id, startTime: startTime, endTime: endTime)
            modelContext.insert(placement)
        }

        try? modelContext.save()
    }

}
