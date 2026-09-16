import SwiftUI

struct WellnessLog: Codable, Identifiable {
    let id: UUID
    let date: Date
    let category: String
    let text: String
}

struct LocalLogsView: View {
    @State private var logs: [WellnessLog] = []
    @State private var category = "Workout"
    @State private var note = ""
    @State private var error: String?
    @State private var confirmDelete = false
    @State private var loadFailed = false
    private let categories = ["Workout", "Study", "Habits", "Mood", "Nutrition", "Budget"]
    private var url: URL { URL.applicationSupportDirectory.appendingPathComponent("logs.json") }

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { _ in
                    HeaderView(eyebrow: "Quick logs", title: "Track", systemImage: "plus")

                    LogComposer(
                        categories: categories,
                        selectedCategory: $category,
                        note: $note,
                        isDisabled: loadFailed,
                        onSave: saveCurrentLog,
                        colorForCategory: categoryColor
                    )

                    if logs.isEmpty {
                        EmptyStatePanel(
                            icon: "tray.fill",
                            title: "No logs yet",
                            detail: "Capture a workout, study block, meal, mood note, or budget detail. Logs stay local on this device.",
                            color: .dilBlue
                        )
                    } else {
                        SectionHeader(title: "History", detail: "\(logs.count) entries")
                        ForEach(logs) { log in
                            LogHistoryCard(log: log, color: categoryColor(log.category))
                        }
                    }

                    DataControlsCard(
                        export: exportText,
                        hasLogs: !logs.isEmpty,
                        onDelete: { confirmDelete = true }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                do {
                    if FileManager.default.fileExists(atPath: url.path) {
                        logs = try JSONDecoder().decode([WellnessLog].self, from: Data(contentsOf: url))
                    }
                } catch {
                    loadFailed = true
                    self.error = "Could not load saved logs. Your file has not been changed. Relaunch to retry."
                }
            }
            .confirmationDialog("Delete all logs permanently?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete logs", role: .destructive) {
                    do {
                        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
                        logs = []
                        loadFailed = false
                    } catch { self.error = "Could not delete logs. Please try again." }
                }
            }
            .alert("Could not complete action", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dilBackground.ignoresSafeArea())
    }

    private var exportText: String? {
        guard let data = try? JSONEncoder().encode(logs) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func saveCurrentLog() {
        let value = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        let updated = [WellnessLog(id: UUID(), date: .now, category: category, text: String(value.prefix(2000)))] + logs
        if save(updated) { note = "" }
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Workout": .dilOrange
        case "Study": .dilBlue
        case "Habits": .dilGreen
        case "Mood": .dilPurple
        case "Nutrition": .dilGold
        case "Budget": .mint
        default: .dilInk
        }
    }

    private func save(_ updated: [WellnessLog]) -> Bool {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(updated).write(to: url, options: [.atomic, .completeFileProtection])
            var fileURL = url
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try fileURL.setResourceValues(values)
            logs = updated
            return true
        } catch {
            self.error = "Could not save the log. Your entry is still here; please try again."
            return false
        }
    }
}

private struct LogComposer: View {
    var categories: [String]
    @Binding var selectedCategory: String
    @Binding var note: String
    var isDisabled: Bool
    var onSave: () -> Void
    var colorForCategory: (String) -> Color

    private var canSave: Bool {
        !isDisabled && !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "New Log", detail: selectedCategory)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category)
                                .font(.caption.weight(.black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 9)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(selectedCategory == category ? .white : colorForCategory(category))
                                .background(
                                    selectedCategory == category ? colorForCategory(category) : colorForCategory(category).opacity(0.13),
                                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $note)
                        .frame(minHeight: 116)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .background(Color.dilBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.dilLine, lineWidth: 1)
                        )

                    if note.isEmpty {
                        Text("What happened?")
                            .font(.body)
                            .foregroundStyle(Color.dilMuted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }

                Button(action: onSave) {
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.headline.weight(.black))
                        Text("Save log")
                            .font(.headline.weight(.black))
                        Spacer()
                        Text("\(min(note.count, 2000))/2000")
                            .font(.caption.weight(.bold))
                            .opacity(0.72)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(canSave ? Color.dilInk : Color.dilMuted, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
        }
    }
}

private struct LogHistoryCard: View {
    var log: WellnessLog
    var color: Color

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    StatusBadge(text: log.category, color: color)
                    Spacer()
                    Text(log.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dilMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Text(log.text)
                    .font(.body)
                    .foregroundStyle(Color.dilInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct DataControlsCard: View {
    var export: String?
    var hasLogs: Bool
    var onDelete: () -> Void

    var body: some View {
        Card(background: Color.dilInk.opacity(0.05)) {
            HStack(spacing: 12) {
                if let export {
                    ShareLink(item: export) {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .font(.headline.weight(.bold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.dilInk)
                }

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Label("Delete logs", systemImage: "trash")
                        .font(.headline.weight(.bold))
                }
                .buttonStyle(.plain)
                .disabled(!hasLogs)
                .opacity(hasLogs ? 1 : 0.45)
            }
        }
    }
}
