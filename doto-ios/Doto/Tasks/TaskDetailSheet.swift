import SwiftUI

struct TaskDetailSheet: View {
    let task: DotoTask
    var onUpdate: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showEdit = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    detailRow(label: "Due", value: task.dueAt?.relativeDue ?? "No due date")
                    detailRow(label: "Points", value: "\(task.points) pts")
                    detailRow(label: "Status", value: (task.status ?? "todo").replacingOccurrences(of: "_", with: " ").capitalized)
                    if let desc = task.description, !desc.isEmpty {
                        detailRow(label: "Notes", value: desc)
                    }
                    if let rep = task.repeat_, rep != "none" {
                        detailRow(label: "Repeat", value: rep.capitalized)
                    }
                }

                if authVM.currentProfile?.isParent == true {
                    Section {
                        Button(role: .destructive) {
                            showDeleteAlert = true
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
                    Task {
                        isDeleting = true
                        try? await APIClient.shared.delete("/tasks/\(task.id)")
                        onUpdate?()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: { onUpdate?(); dismiss() }) {
            AddEditTaskView(task: task)
        }
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
