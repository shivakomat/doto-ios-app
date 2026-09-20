import SwiftUI

struct TaskDetailSheet: View {
    let task: DotoTask
    var onUpdate: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showEdit = false
    @State private var showDeleteAlert = false
    @State private var showDeleteScopeDialog = false
    @State private var isDeleting = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    if task.type == .routine {
                        HStack {
                            Text("Time of day")
                                .font(.system(size: 13))
                                .foregroundColor(.textMuted)
                            Spacer()
                            Image(systemName: task.timeOfDayIcon)
                                .font(.system(size: 12))
                            Text(task.timeOfDayLabel ?? "—")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.textPrimary)
                    } else {
                        detailRow(label: "Due", value: task.dueDate?.relativeDue ?? "No due date")
                    }
                    detailRow(label: "Type", value: task.type.label)
                    HStack {
                        Text("Icon")
                            .font(.system(size: 13))
                            .foregroundColor(.textMuted)
                        Spacer()
                        Image(systemName: task.resolvedIcon)
                            .font(.system(size: 14))
                            .foregroundColor(task.iconColor)
                    }
                    if task.type.earnsPoints {
                        detailRow(label: "Points", value: "\(task.points) pts")
                    }
                    detailRow(label: "Status", value: (task.status ?? "todo").replacingOccurrences(of: "_", with: " ").capitalized)
                    if let notes = task.notes, !notes.isEmpty {
                        detailRow(label: "Notes", value: notes)
                    }
                    if task.isRecurring {
                        detailRow(label: "Repeat", value: recurrenceSummary)
                    }
                }

                if authVM.currentProfile?.isParent == true {
                    Section {
                        Button(role: .destructive) {
                            if task.isRecurring {
                                showDeleteScopeDialog = true
                            } else {
                                showDeleteAlert = true
                            }
                        } label: {
                            Text("Delete Task")
                        }
                    }
                }
            }
            .navigationTitle(task.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if authVM.currentProfile?.isParent == true {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") { showEdit = true }
                    }
                }
            }
            .alert("Delete this task?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    delete(scope: nil)
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Delete recurring task", isPresented: $showDeleteScopeDialog, titleVisibility: .visible) {
                Button("This task only", role: .destructive) { delete(scope: .this) }
                Button("This and future tasks", role: .destructive) { delete(scope: .future) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Delete just this occurrence, or this and all future occurrences?")
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: { onUpdate?(); dismiss() }) {
            AddEditTaskView(task: task)
        }
    }

    private func delete(scope: TaskScope?) {
        Task {
            isDeleting = true
            let path = scope.map { "/tasks/\(task.id)?scope=\($0.rawValue)" } ?? "/tasks/\(task.id)"
            try? await APIClient.shared.delete(path)
            onUpdate?()
            dismiss()
        }
    }

    private var recurrenceSummary: String {
        var value = task.recurrence.summary(dueWeekday: task.dueWeekday)
        if let end = task.recurrence.endSummary {
            value += " · \(end)"
        }
        return value
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.textPrimary)
        }
    }
}
