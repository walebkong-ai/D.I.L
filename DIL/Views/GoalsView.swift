import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var appState: AppState
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

                    MetricSummaryCard(title: "Today's plan", status: "\(appState.dailyPlan.tasks.filter(\.isComplete).count) of \(appState.dailyPlan.tasks.count) complete",
                                      value: "\(appState.dailyPlan.tasks.filter { !$0.isComplete }.count) remaining")

                    if appState.dailyPlan.tasks.isEmpty {
                        EmptyStatePanel(
                            icon: "plus.circle.fill",
                            title: "No goals yet",
                            detail: "Create your first daily goal.",
                            color: .dilGreen
                        )
                    } else {
                        SectionHeader(title: "Next up")
                        ForEach(appState.dailyPlan.tasks.filter { !$0.isComplete }.sorted { $0.points > $1.points }) { task in
                            GoalSummaryRow(task: task)
                        }
                        if appState.dailyPlan.tasks.contains(where: \.isComplete) {
                            DisclosureGroup("Completed goals") {
                                ForEach(appState.dailyPlan.tasks.filter(\.isComplete)) { task in GoalSummaryRow(task: task) }
                            }
                        }
                        NavigationLink("View daily history") { GoalHistoryView() }
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
                        .background(Color.dilHero, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dilBackground.ignoresSafeArea())
    }

}

struct GoalSummaryRow: View {
    @EnvironmentObject private var appState: AppState
    var task: DailyTask
    var body: some View {
        HStack(spacing: 8) {
            Button { appState.completeTask(task) } label: {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title2).frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(task.isComplete ? "Mark incomplete" : "Complete") \(task.title)")
            NavigationLink { GoalDetailView(taskID: task.id) } label: {
                DetailDisclosure(title: task.title, value: task.isComplete ? "Complete" : "\(task.points) pts · Incomplete")
            }.buttonStyle(.plain)
        }
        .foregroundStyle(task.isComplete ? Color.dilMuted : Color.dilInk)
    }
}

private struct GoalDetailView: View {
    @EnvironmentObject private var appState: AppState
    let taskID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var editing = false
    @State private var deleting = false
    private var task: DailyTask? { appState.dailyPlan.tasks.first { $0.id == taskID } }
    var body: some View {
        List {
            if let task {
                Section {
                    MetricRow(title: task.categoryName, value: task.title, detail: task.isComplete ? "Complete" : "Next step: complete this daily goal")
                    if !task.detail.isEmpty { Text(task.detail) }
                    MetricRow(title: "Points", value: "\(task.points) pts")
                    Button(task.isComplete ? "Mark incomplete" : "Mark complete") { appState.completeTask(task) }
                }
                Section("Manage goal") {
                    Button("Edit goal", systemImage: "pencil") { editing = true }
                    Button("Delete goal", systemImage: "trash", role: .destructive) { deleting = true }
                }
            } else { Text("This goal is no longer in today's plan.") }
        }
        .navigationTitle("Goal").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editing) {
            if let task {
                GoalEditorView(title: "Edit Goal", categories: appState.dailyPlan.categories.map(\.name), task: task) { title, detail, points, category in
                    appState.updateTask(task, title: title, detail: detail, points: points, categoryName: category)
                }
            }
        }
        .confirmationDialog("Delete this goal?", isPresented: $deleting, titleVisibility: .visible) {
            Button("Delete goal", role: .destructive) {
                if let index = appState.dailyPlan.tasks.firstIndex(where: { $0.id == taskID }) {
                    appState.deleteTasks(at: IndexSet(integer: index))
                }
                dismiss()
            }
        }
    }
}

struct GoalHistoryView: View {
    @EnvironmentObject private var appState: AppState
    var body: some View {
        List {
            ForEach(appState.history.sorted { $0.date > $1.date }, id: \.date) { day in
                NavigationLink {
                    List(day.tasks) { task in
                        MetricRow(title: task.title, value: task.isComplete ? "Complete" : "Incomplete", detail: "\(task.points) pts · \(task.categoryName)")
                        if !task.detail.isEmpty { Text(task.detail) }
                    }.navigationTitle(day.date.formatted(date: .abbreviated, time: .omitted))
                } label: {
                    MetricRow(title: day.date.formatted(date: .abbreviated, time: .omitted), value: "\(day.tasks.filter(\.isComplete).count) of \(day.tasks.count) complete")
                }
            }
        }.navigationTitle("Daily history").navigationBarTitleDisplayMode(.inline)
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
