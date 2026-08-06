import SwiftUI

public struct TaskManagementView: View {
    @Environment(TaskEngine.self) private var engine

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public var body: some View {
        let _ = engine.dataVersion
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("任务管理")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppConstants.Colors.primaryTextDark)
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
            .background(AppConstants.Colors.backgroundGrey)
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
        let _ = engine.dataVersion
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
        .background(AppConstants.Colors.backgroundGrey)
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

    private var placementSummary: String? {
        guard let placement = item.task.defaultPlacement else { return nil }
        guard placement.duration > 0 else { return placement.startTime }
        return "\(placement.startTime) · \(placement.duration) 分钟"
    }

    var body: some View {
        let isDone = item.instance?.status == .done

        HStack(spacing: 12) {
            Button(action: onEdit) {
                HStack(spacing: 12) {
                    Image(systemName: item.task.iconSymbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(hex: item.task.tintHex))
                        .frame(width: 34, height: 34)
                        .background(Color(hex: item.task.tintHex).opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.task.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isDone ? Color.secondary.opacity(0.6) : AppConstants.Colors.primaryTextDark)
                            .overlay(alignment: .leading) {
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.6))
                                        .frame(width: isDone ? geo.size.width : 0, height: 2)
                                        .frame(maxHeight: .infinity, alignment: .center)
                                        .animation(.easeInOut(duration: 0.35), value: isDone)
                                }
                            }

                        if let summary = placementSummary {
                            Text(summary)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 8)
                }
            }
            .buttonStyle(.plain)

            TaskStatusCheckbox(
                isDone: isDone,
                tintColor: Color(hex: item.task.tintHex),
                mode: .standard,
                onToggle: onToggle
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppConstants.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private extension TaskManagementCategory {
    var title: String {
        AppConstants.Categories.title(for: self)
    }

    var iconSymbol: String {
        AppConstants.Categories.iconSymbol(for: self)
    }

    var colorHex: String {
        AppConstants.Categories.colorHex(for: self)
    }
}
