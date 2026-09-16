import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var editingTask: DailyTask?
    @State private var isAddingTask = false

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { _ in
                    HeaderView(eyebrow: "Daily plan", title: "Goals", systemImage: "target")

                    if appState.dailyPlan.tasks.isEmpty {
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("No goals yet")
                                    .font(.title3.weight(.bold))
                                Text("Add the goals you want to finish today. Completed goals are saved on this device and immediately update your daily points.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.dilMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else {
                        ForEach(appState.dailyPlan.tasks) { task in
                            GoalCard(task: task) {
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
                        Label("Add daily goal", systemImage: "plus.circle.fill")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.dilInk)
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
        .background(Color.white.ignoresSafeArea())
    }
}

private struct GoalCard: View {
    var task: DailyTask
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
                            .foregroundStyle(task.isComplete ? Color.dilGreen : Color.dilMuted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(task.isComplete ? "Mark incomplete" : "Mark complete")

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
                }

                HStack {
                    Label(task.categoryName, systemImage: "tag.fill")
                    Spacer()
                    Text("\(task.points) pts")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.dilMuted)
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
