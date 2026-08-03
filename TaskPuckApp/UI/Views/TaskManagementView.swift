import SwiftUI

public struct TaskManagementView: View {
    @Environment(TaskEngine.self) private var engine

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("任务管理")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(TaskManagementCategory.allCases) { category in
                            NavigationLink(value: category) {
                                TaskCategoryCard(
                                    title: category.title,
                                    count: engine.managedTasks(for: category).count,
                                    iconSymbol: category.iconSymbol,
                                    color: Color(hex: category.colorHex)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 110)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.97))
            .navigationDestination(for: TaskManagementCategory.self) { category in
                TaskManagementDetailView(category: category)
            }
            .onAppear {
                engine.prepareTaskManagement()
            }
        }
    }
}

private struct TaskCategoryCard: View {
    let title: String
    let count: Int
    let iconSymbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: iconSymbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Spacer()
                Text(count, format: .number)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .background(color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: color.opacity(0.2), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)，\(count) 个任务")
    }
}

private struct TaskManagementDetailView: View {
    @Environment(TaskEngine.self) private var engine

    let category: TaskManagementCategory
    @State private var selectedItem: ManagedTaskItem?

    private var items: [ManagedTaskItem] {
        engine.managedTasks(for: category)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 10) {
                if items.isEmpty {
                    ContentUnavailableView(
                        "暂无任务",
                        systemImage: "checklist",
                        description: Text("创建任务后，它会出现在这里")
                    )
                    .padding(.top, 80)
                } else {
                    ForEach(items) { item in
                        ManagedTaskRow(item: item) {
                            selectedItem = item
                        } onToggle: {
                            guard let instance = item.instance else { return }
                            engine.toggleTaskStatus(instance: instance)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97))
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedItem) { item in
            CreateTaskSheet(task: item.task, status: item.instance?.status ?? .todo)
                .environment(engine)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct ManagedTaskRow: View {
    let item: ManagedTaskItem
    let onEdit: () -> Void
    let onToggle: () -> Void

    private var placementText: String? {
        guard let placement = item.task.defaultPlacement else { return nil }
        guard placement.duration > 0 else { return placement.startTime }
        return "\(placement.startTime) · \(placement.duration) 分钟"
    }

    var body: some View {
        HStack(spacing: 12) {
            // 左侧：任务信息（点击空白处和文字均可编辑）
            Button(action: onEdit) {
                HStack(spacing: 12) {
                    Image(systemName: item.task.iconSymbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(hex: item.task.tintHex))
                        .frame(width: 34, height: 34)
                        .background(Color(hex: item.task.tintHex).opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.task.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .strikethrough(item.instance?.status == .done, color: .secondary)
                        if let placementText {
                            Text(placementText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("无开始时间")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 8) // 撑开中间空白，把勾选框推到最右边
                }
            }
            .buttonStyle(.plain)

            // 右侧：勾选框
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(Color(hex: item.task.tintHex), lineWidth: 3)
                        .frame(width: 26, height: 26)
                    if item.instance?.status == .done {
                        Circle()
                            .fill(Color(hex: item.task.tintHex))
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(item.instance == nil)
            .opacity(item.instance == nil ? 0.35 : 1)
            .accessibilityLabel(item.instance?.status == .done ? "标记为未完成" : "标记为已完成")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private extension TaskManagementCategory {
    var title: String {
        switch self {
        case .today: "今天"
        case .daily: "每日"
        case .weekly: "每周"
        case .monthly: "每月"
        case .dateRange: "日期范围"
        case .once: "仅一次"
        }
    }

    var iconSymbol: String {
        switch self {
        case .today: "calendar"
        case .daily: "arrow.triangle.2.circlepath"
        case .weekly: "calendar.badge.clock"
        case .monthly: "calendar"
        case .dateRange: "calendar.badge.plus"
        case .once: "1.circle"
        }
    }

    var colorHex: String {
        switch self {
        case .today: "4F83CC"
        case .daily: "2C8B73"
        case .weekly: "8D3F68"
        case .monthly: "D58A3A"
        case .dateRange: "6E6AAE"
        case .once: "D05D69"
        }
    }
}
