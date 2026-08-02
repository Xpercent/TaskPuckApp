import Foundation
import SwiftUI
import SwiftData

public struct DisplayTimelineItem: Identifiable, Equatable {
    public var id: String { instance.id }
    public var task: TaskEntity
    public var instance: TaskInstanceEntity
    public var placement: TimelinePlacementEntity?
}

@Observable
@MainActor
public final class TaskEngine {
    private var modelContext: ModelContext
    public var selectedDateString: String
    public var isReadOnly: Bool = false
    public var toastMessage: String?

    public init(modelContext: ModelContext, initialDate: String = "2026-08-01") {
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
            case .weekly: return true
            case .dateRange(let start, let end, _):
                if targetDate >= start && targetDate <= end { return true }
            }
        }
        return rules.isEmpty
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

    // MARK: - Actions

    public func toggleTaskStatus(instance: TaskInstanceEntity) {
        if isReadOnly {
            self.toastMessage = "历史排期不可篡改"
            return
        }
        instance.status = (instance.status == .done) ? .todo : .done
        try? modelContext.save()
    }

    public func createNewTask(title: String, durationMinutes: Int, recurrence: RecurrenceRule, startTime: String? = nil) {
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
            status: .todo
        )
        modelContext.insert(newInstance)

        if let startTime {
            let endTime = DateUtils.calculateEndTime(startTime: startTime, durationMinutes: durationMinutes)
            let placement = TimelinePlacementEntity(instanceId: newInstance.id, startTime: startTime, endTime: endTime)
            modelContext.insert(placement)
        }

        try? modelContext.save()
    }

    // MARK: - MVP Mock Data Seeder

    public func initializeMVPData() {
        try? modelContext.delete(model: TimelinePlacementEntity.self)
        try? modelContext.delete(model: TaskInstanceEntity.self)
        try? modelContext.delete(model: TaskEntity.self)

        let task1 = TaskEntity(title: "早晨活力", iconSymbol: "alarm.fill", priority: .high, recurrenceRules: [.daily], defaultPlacement: DefaultPlacement(startTime: "07:00", duration: 15))
        let task2 = TaskEntity(title: "回复邮件", iconSymbol: "at", priority: .urgent, recurrenceRules: [.daily], defaultPlacement: DefaultPlacement(startTime: "10:00", duration: 15))
        let task3 = TaskEntity(title: "回复邮件", iconSymbol: "at", priority: .medium, recurrenceRules: [.daily], defaultPlacement: DefaultPlacement(startTime: "10:08", duration: 15))
        let task4 = TaskEntity(title: "放松心情", iconSymbol: "moon.fill", priority: .low, recurrenceRules: [.daily], defaultPlacement: DefaultPlacement(startTime: "21:08", duration: 15))

        modelContext.insert(task1)
        modelContext.insert(task2)
        modelContext.insert(task3)
        modelContext.insert(task4)

        let targetDate = "2026-08-01"

        let inst1 = TaskInstanceEntity(taskId: task1.id, originalDate: targetDate, currentDate: targetDate, status: .done)
        let inst2 = TaskInstanceEntity(taskId: task2.id, originalDate: targetDate, currentDate: targetDate, status: .todo)
        let inst3 = TaskInstanceEntity(taskId: task3.id, originalDate: targetDate, currentDate: targetDate, status: .todo)
        let inst4 = TaskInstanceEntity(taskId: task4.id, originalDate: targetDate, currentDate: targetDate, status: .todo)

        modelContext.insert(inst1)
        modelContext.insert(inst2)
        modelContext.insert(inst3)
        modelContext.insert(inst4)

        modelContext.insert(TimelinePlacementEntity(instanceId: inst1.id, startTime: "07:00", endTime: "07:15"))
        modelContext.insert(TimelinePlacementEntity(instanceId: inst2.id, startTime: "10:00", endTime: "10:15"))
        modelContext.insert(TimelinePlacementEntity(instanceId: inst3.id, startTime: "10:08", endTime: "10:23"))
        modelContext.insert(TimelinePlacementEntity(instanceId: inst4.id, startTime: "21:08", endTime: "21:23"))

        try? modelContext.save()
    }
}