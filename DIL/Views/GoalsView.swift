import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var editingTask: DailyTask?
    @State private var isAddingTask = false

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { _ in
                    if let message = appState.persistenceMessage {
                        Text(message).font(.footnote).foregroundStyle(.red)
                        Button("Retry loading goals") { appState.retryActivityLoad() }
                    }
                    HeaderView(eyebrow: "Daily plan", title: "Goals", systemImage: "target")

                    HStack(spacing: 10) {
                        MetricBlock(title: "Goals", value: "\(appState.dailyPlan.tasks.count)", detail: "today", color: .dilBlue)
                        MetricBlock(title: "Complete", value: "\(appState.dailyPlan.tasks.filter(\.isComplete).count)", detail: "done", color: .dilGreen)
                        MetricBlock(title: "Points", value: "\(appState.dailyPointTotal)", detail: "earned", color: .dilOrange)
                    }

                    if appState.dailyPlan.tasks.isEmpty {
                        EmptyStatePanel(
                            icon: "plus.circle.fill",
                            title: "No goals yet",
                            detail: "Add the goals you want to finish today. Completed goals are saved on this device and immediately update your points.",
                            color: .dilGreen
                        )
                    } else {
                        SectionHeader(title: "Plan Stack", detail: "\(appState.dailyPlan.tasks.count) items")
                        ForEach(appState.dailyPlan.tasks) { task in
                            GoalCard(task: task, categoryColor: categoryColor(for: task.categoryName)) {
                                appState.completeTask(task)
                            } onEdit: {
                                editingTask = task
                            } onDelete: {
                                if let index = appState.dailyPlan.tasks.firstIndex(where: { $0.id == task.id }) {
                                    appState.deleteTasks(at: IndexSet(integer: index))
                                }
                            }
                        }
                    }

                    Button {
                        isAddingTask = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.headline.weight(.black))
                            Text("Add daily goal")
                                .font(.headline.weight(.black))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.subheadline.weight(.black))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .background(Color.dilInk, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isAddingTask) {
            GoalEditorView(
                title: "Add Goal",
                categories: appState.dailyPlan.categories.map(\.name)
            ) { title, detail, points, category in
                appState.addTask(
                    title: title,
                    detail: detail,
                    points: points,
                    categoryName: category
                )
            }
        }
        .sheet(item: $editingTask) { task in
            GoalEditorView(
                title: "Edit Goal",
                categories: appState.dailyPlan.categories.map(\.name),
                task: task
            ) { title, detail, points, category in
                appState.updateTask(
                    task,
                    title: title,
                    detail: detail,
                    points: points,
                    categoryName: category
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dilBackground.ignoresSafeArea())
    }

    private func categoryColor(for name: String) -> Color {
        appState.dailyPlan.categories.first(where: { $0.name == name })?.color ?? .dilInk
    }
}

private struct GoalCard: View {
    var task: DailyTask
    var categoryColor: Color
    var onToggle: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Button(action: onToggle) {
                        Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(task.isComplete ? Color.dilGreen : categoryColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(task.isComplete ? "Mark incomplete" : "Mark complete")
                    .frame(minWidth: 44, minHeight: 44)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(task.title)
                            .font(.title3.weight(.bold))
                            .strikethrough(task.isComplete)
                        if !task.detail.isEmpty {
                            Text(task.detail)
                                .font(.subheadline)
                                .foregroundStyle(Color.dilMuted)
                        }
                    }

                    Spacer(minLength: 8)

                    Menu {
                        Button("Edit", systemImage: "pencil", action: onEdit)
                        Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(Color.dilMuted)
                    }
                    .accessibilityLabel("Goal actions")
                    .frame(minWidth: 44, minHeight: 44)
                }

                HStack {
                    StatusBadge(text: task.categoryName, color: categoryColor, icon: "tag.fill")
                    Spacer()
                    Text("\(task.points) pts")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.dilInk)
                }
            }
        }
    }
}

private struct GoalEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let categories: [String]
    let onSave: (String, String, Int, String) -> Void

    @State private var goalTitle: String
    @State private var detail: String
    @State private var points: Int
    @State private var category: String

    init(
        title: String,
        categories: [String],
        task: DailyTask? = nil,
        onSave: @escaping (String, String, Int, String) -> Void
    ) {
        self.title = title
        self.categories = categories
        self.onSave = onSave
        _goalTitle = State(initialValue: task?.title ?? "")
        _detail = State(initialValue: task?.detail ?? "")
        _points = State(initialValue: task?.points ?? 10)
        _category = State(initialValue: task?.categoryName ?? categories.first ?? "Habits")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("What do you want to finish?", text: $goalTitle)
                    TextField("Optional detail", text: $detail, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Points") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    Stepper("\(points) points", value: $points, in: 1...120, step: 5)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(goalTitle, detail, points, category)
                        dismiss()
                    }
                    .disabled(goalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
