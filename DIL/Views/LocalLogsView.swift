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
    @State private var composing = false
    @State private var showingHistory = false
    private let categories = ["Workout", "Study", "Habits", "Mood", "Nutrition", "Budget"]
    private var url: URL { URL.applicationSupportDirectory.appendingPathComponent("logs.json") }

    var body: some View {
        NavigationStack {
            ScreenBackground {
                AdaptiveScreen { _ in
                    HeaderView(eyebrow: "Quick logs", title: "Track", systemImage: "plus")

                    SectionHeader(title: "Log something")
                    ForEach(categories, id: \.self) { item in
                        Button {
                            category = item
                            composing = true
                        } label: {
                            Label(item, systemImage: categoryIcon(item))
                                .font(.headline).foregroundStyle(Color.dilInk)
                                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                                .contentShape(Rectangle())
                        }.buttonStyle(.plain).disabled(loadFailed)
                    }

                    if logs.isEmpty {
                        EmptyStatePanel(
                            icon: "tray.fill",
                            title: "No logs yet",
                            detail: "Choose a category to record your first entry.",
                            color: .dilBlue
                        )
                    } else {
                        SectionHeader(title: "Recent entries")
                        ForEach(logs.prefix(3)) { log in
                            NavigationLink {
                                List { MetricRow(title: log.category, value: log.date.formatted()); Text(log.text) }
                                    .navigationTitle("Log entry").navigationBarTitleDisplayMode(.inline)
                            } label: {
                                DetailDisclosure(title: log.category, value: log.date.formatted(date: .abbreviated, time: .shortened))
                            }.buttonStyle(.plain)
                        }
                    }
                    Button("View history and data controls") { showingHistory = true }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $composing) {
                NavigationStack {
                    ScreenBackground {
                        AdaptiveScreen { _ in
                            LogComposer(note: $note, isDisabled: loadFailed, onSave: saveCurrentLog)
                        }
                    }
                    .navigationTitle(category).navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { composing = false } } }
                    .alert("Could not save log", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                        Button("OK") { error = nil }
                    } message: { Text(error ?? "") }
                }
            }
            .sheet(isPresented: $showingHistory) {
                NavigationStack {
                    List {
                        if logs.isEmpty { Text("No logs yet") }
                        ForEach(logs) { log in
                            NavigationLink {
                                List { MetricRow(title: log.category, value: log.date.formatted()); Text(log.text) }.navigationTitle("Log entry")
                            } label: { MetricRow(title: log.category, value: log.date.formatted(date: .abbreviated, time: .shortened)) }
                        }
                        Section("Data controls") {
                            if let exportText { ShareLink("Export logs", item: exportText) }
                            Button("Delete all logs", role: .destructive) {
                                showingHistory = false
                                confirmDelete = true
                            }.disabled(logs.isEmpty && !loadFailed)
                        }
                    }.navigationTitle("Log history")
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { showingHistory = false } } }
                }
            }
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
        if save(updated) { note = ""; composing = false }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Workout": "dumbbell"
        case "Study": "book"
        case "Habits": "checkmark.circle"
        case "Mood": "face.smiling"
        case "Nutrition": "fork.knife"
        default: "creditcard"
        }
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
    @Binding var note: String
    var isDisabled: Bool
    var onSave: () -> Void

    private var canSave: Bool {
        !isDisabled && !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "New entry")


                ZStack(alignment: .topLeading) {
                    TextEditor(text: $note)
                        .accessibilityLabel("Log note")
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
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                        Image(systemName: "checkmark")
                            .font(.headline.weight(.black))
                        Text("Save log")
                            .font(.headline.weight(.black))
                        }
                        Text("\(min(note.count, 2000))/2000")
                            .font(.caption.weight(.bold))
                            .opacity(0.72)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(canSave ? Color.dilHero : Color.dilMuted, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
        }
    }
}
