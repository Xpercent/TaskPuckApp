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

public enum TaskManagementCategory: CaseIterable, Hashable, Identifiable {
    case today
    case daily
    case weekly
    case monthly
    case dateRange
    case once

    public var id: Self { self }
}

public struct ManagedTaskItem: Identifiable {
    public let task: TaskEntity
    public let instance: TaskInstanceEntity?

    public var id: String { task.id }
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

    public func ensureInstances(for targetDate: String) {
        let taskDescriptor = FetchDescriptor<TaskEntity>(predicate: #Predicate { !$0.isArchived })
        guard let tasks = try? modelContext.fetch(taskDescriptor) else { return }

        let targetDateObj = DateUtils.date(from: targetDate) ?? Date()
        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: targetDateObj)

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
            case .daily:
                return true
            case .once(let date):
                if date == targetDate { return true }
            case .weekly(let weekdays):
                if weekdays.contains(weekday(for: weekdayIndex)) { return true }
            case .monthly(let day):
                let targetDateObject = DateUtils.date(from: targetDate) ?? Date()
                let targetDay = DateUtils.calendar.component(.day, from: targetDateObject)
                if day == 0,
                   let lastDay = DateUtils.calendar.range(of: .day, in: .month, for: targetDateObject)?.count,
                   targetDay == lastDay { return true }
                if targetDay == day { return true }
            case .monthlyMultiple(let days):
                let targetDateObject = DateUtils.date(from: targetDate) ?? Date()
                let targetDay = DateUtils.calendar.component(.day, from: targetDateObject)
                let isLastDay = DateUtils.calendar.range(of: .day, in: .month, for: targetDateObject)?.count == targetDay
                if days.contains(targetDay) || (days.contains(0) && isLastDay) { return true }
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

    public func autoRollOverdueTasks() {
        let today = DateUtils.todayString()
        let instanceDescriptor = FetchDescriptor<TaskInstanceEntity>(
            predicate: #Predicate { $0.currentDate < today && $0.statusRaw == "TODO" }
        )
        guard let overdueInstances = try? modelContext.fetch(instanceDescriptor) else { return }

        for instance in overdueInstances {
            instance.currentDate = today
        }
        try? modelContext.save()
    }

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

        displayItems.sort { a, b in
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

    public func prepareTaskManagement() {
        ensureInstances(for: DateUtils.todayString())
    }

    public func managedTasks(for category: TaskManagementCategory) -> [ManagedTaskItem] {
        let today = DateUtils.todayString()
        let activeTasks = fetchActiveTasks()
        let instances = fetchInstances(for: today)
        let instancesByTaskID = Dictionary(
            instances.map { ($0.taskId, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let tasks: [TaskEntity]
        switch category {
        case .today:
            let taskIDs = Set(instances.map(\.taskId))
            tasks = activeTasks.filter { taskIDs.contains($0.id) }
        case .daily, .weekly, .monthly, .dateRange, .once:
            tasks = activeTasks.filter { task in
                task.recurrenceRules.contains { rule in
                    category.matches(rule)
                }
            }
        }

        return tasks
            .map { ManagedTaskItem(task: $0, instance: instancesByTaskID[$0.id]) }
            .sorted(by: taskManagementSort)
    }

    public func toggleTaskStatus(instance: TaskInstanceEntity) {
        if isReadOnly {
            toastMessage = "历史排期不可篡改"
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
        iconSymbol: String = "at",
        tintHex: String = "EE8C8C",
        initialStatus: InstanceStatus = .todo
    ) {
        if isReadOnly {
            toastMessage = "历史排期不可篡改"
            return
        }

        let defaultPlacement = startTime.map { DefaultPlacement(startTime: $0, duration: durationMinutes) }
        let newTask = TaskEntity(
            title: title,
            iconSymbol: iconSymbol,
            tintHex: tintHex,
            priority: .urgent,
            recurrenceRules: [recurrence],
            defaultPlacement: defaultPlacement
        )
        modelContext.insert(newTask)

        let initialDate = firstOccurrence(for: recurrence, from: selectedDateString)
        let newInstance = TaskInstanceEntity(
            taskId: newTask.id,
            originalDate: initialDate,
            currentDate: initialDate,
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

    public func updateTask(
        _ task: TaskEntity,
        title: String,
        durationMinutes: Int,
        recurrence: RecurrenceRule,
        startTime: String?,
        iconSymbol: String,
        tintHex: String
    ) {
        if isReadOnly {
            toastMessage = "历史排期不可篡改"
            return
        }

        task.title = title
        task.iconSymbol = iconSymbol
        task.tintHex = tintHex
        task.recurrenceRules = [recurrence]
        task.defaultPlacement = startTime.map { DefaultPlacement(startTime: $0, duration: durationMinutes) }

        let instances = fetchInstances(forTaskID: task.id)
        for instance in instances {
            updatePlacement(for: instance, startTime: startTime, durationMinutes: durationMinutes)
        }
        try? modelContext.save()
    }

    public func deleteTask(_ task: TaskEntity) {
        if isReadOnly {
            toastMessage = "历史排期不可篡改"
            return
        }

        for instance in fetchInstances(forTaskID: task.id) {
            deletePlacement(for: instance)
            modelContext.delete(instance)
        }
        modelContext.delete(task)
        try? modelContext.save()
    }

    public func clearAllData() {
        fetchAll(TimelinePlacementEntity.self).forEach(modelContext.delete)
        fetchAll(TaskInstanceEntity.self).forEach(modelContext.delete)
        fetchAll(TaskEntity.self).forEach(modelContext.delete)
        try? modelContext.save()
    }

    public func initializeSampleData() {
        clearAllData()
        let today = DateUtils.todayString()
        let tomorrow = DateUtils.string(from: DateUtils.calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        selectedDateString = today
        isReadOnly = false

        createNewTask(title: "晨间计划", durationMinutes: 30, recurrence: .daily, startTime: "08:00", iconSymbol: "sun.max.fill", tintHex: "FF9D73")
        createNewTask(title: "项目回顾", durationMinutes: 45, recurrence: .weekly(weekdays: [.mon, .wed, .fri]), startTime: "10:00", iconSymbol: "briefcase.fill", tintHex: "5E86A8")
        createNewTask(title: "整理账单", durationMinutes: 20, recurrence: .monthlyMultiple(days: [1, 15]), startTime: nil, iconSymbol: "list.bullet.rectangle", tintHex: "8CBD68")
        createNewTask(title: "旅行准备", durationMinutes: 60, recurrence: .dateRange(start: today, end: tomorrow, autoArchive: nil), startTime: "19:00", iconSymbol: "suitcase.rolling.fill", tintHex: "8D3F68")
        createNewTask(title: "预约体检", durationMinutes: 0, recurrence: .once(date: tomorrow), startTime: nil, iconSymbol: "heart.text.square.fill", tintHex: "F49898")
        toastMessage = "已初始化测试数据"
    }

    private func fetchActiveTasks() -> [TaskEntity] {
        let descriptor = FetchDescriptor<TaskEntity>(predicate: #Predicate { !$0.isArchived })
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchInstances(for date: String) -> [TaskInstanceEntity] {
        let descriptor = FetchDescriptor<TaskInstanceEntity>(predicate: #Predicate { $0.currentDate == date })
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchInstances(forTaskID taskID: String) -> [TaskInstanceEntity] {
        let descriptor = FetchDescriptor<TaskInstanceEntity>(predicate: #Predicate { $0.taskId == taskID })
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchAll<Model: PersistentModel>(_ type: Model.Type) -> [Model] {
        (try? modelContext.fetch(FetchDescriptor<Model>())) ?? []
    }

    private func taskManagementSort(_ lhs: ManagedTaskItem, _ rhs: ManagedTaskItem) -> Bool {
        let lhsTime = lhs.task.defaultPlacement?.startTime
        let rhsTime = rhs.task.defaultPlacement?.startTime
        switch (lhsTime, rhsTime) {
        case (nil, nil):
            return lhs.task.title.localizedStandardCompare(rhs.task.title) == .orderedAscending
        case (nil, _?):
            return true
        case (_?, nil):
            return false
        case let (lhsTime?, rhsTime?):
            return lhsTime == rhsTime
                ? lhs.task.title.localizedStandardCompare(rhs.task.title) == .orderedAscending
                : lhsTime < rhsTime
        }
    }

    private func updatePlacement(
        for instance: TaskInstanceEntity,
        startTime: String?,
        durationMinutes: Int
    ) {
        let instanceID = instance.id
        let descriptor = FetchDescriptor<TimelinePlacementEntity>(
            predicate: #Predicate { $0.instanceId == instanceID }
        )
        let placements = (try? modelContext.fetch(descriptor)) ?? []

        guard let startTime else {
            placements.forEach(modelContext.delete)
            return
        }

        let endTime = DateUtils.calculateEndTime(startTime: startTime, durationMinutes: durationMinutes)
        if let placement = placements.first {
            placement.startTime = startTime
            placement.endTime = endTime
            placements.dropFirst().forEach(modelContext.delete)
        } else {
            modelContext.insert(TimelinePlacementEntity(instanceId: instance.id, startTime: startTime, endTime: endTime))
        }
    }

    private func deletePlacement(for instance: TaskInstanceEntity) {
        let instanceID = instance.id
        let descriptor = FetchDescriptor<TimelinePlacementEntity>(
            predicate: #Predicate { $0.instanceId == instanceID }
        )
        ((try? modelContext.fetch(descriptor)) ?? []).forEach(modelContext.delete)
    }

    private func firstOccurrence(for rule: RecurrenceRule, from dateString: String) -> String {
        if case .once(let date) = rule { return date }
        if case .dateRange(let start, let end, _) = rule {
            if dateString < start { return start }
            if dateString > end { return start }
            return dateString
        }

        guard let startDate = DateUtils.date(from: dateString) else { return dateString }
        for offset in 0...366 {
            guard let candidate = DateUtils.calendar.date(byAdding: .day, value: offset, to: startDate) else { continue }
            let candidateString = DateUtils.string(from: candidate)
            if matchesRecurrence(
                rules: [rule],
                targetDate: candidateString,
                weekdayIndex: DateUtils.calendar.component(.weekday, from: candidate)
            ) {
                return candidateString
            }
        }
        return dateString
    }
}

private extension TaskManagementCategory {
    func matches(_ rule: RecurrenceRule) -> Bool {
        switch (self, rule) {
        case (.daily, .daily), (.weekly, .weekly), (.monthly, .monthly),
             (.monthly, .monthlyMultiple), (.dateRange, .dateRange), (.once, .once):
            true
        default:
            false
        }
    }
}
