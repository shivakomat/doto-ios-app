import SwiftUI

struct TaskCreateRequest: Encodable {
    let title: String
    let assignedTo: String?
    let dueAt: Date?
    let points: Int
    let notes: String?
    let `repeat`: String?
    let rewardGoalId: String?
}

struct AddEditTaskView: View {
    let task: DotoTask?
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var assignedToId: String = ""
    @State private var dueDate = Date()
    @State private var points = 10
    @State private var notes = ""
    @State private var repeatOption = "none"
    @State private var rewardGoalId: String? = nil
    @State private var availableGoals: [Reward] = []
    @State private var members: [Profile] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let repeatOptions = ["none", "daily", "weekly"]
    private var isEdit: Bool { task != nil }
    private var isParent: Bool { authVM.currentProfile?.isParent == true }
    private var assignedMember: Profile? { members.first { $0.id == assignedToId } }
    private var assignedIsChild: Bool { assignedMember?.role == "child" }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Task name", text: $title)
                }

                Section(header: Text("Assign to")) {
                    ForEach(members) { member in
                        Button {
                            assignedToId = member.id
                        } label: {
                            HStack(spacing: 10) {
                                AvatarView(
                                    name: member.displayName,
                                    color: member.color,
                                    size: 28,
                                    isActive: assignedToId == member.id
                                )
                                .opacity(assignedToId == member.id ? 1 : 0.3)
                                Text(member.displayName)
                                    .foregroundColor(.textPrimary)
                                if member.id == authVM.currentProfile?.id {
                                    Text("(you)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textMuted)
                                }
                                Spacer()
                                if assignedToId == member.id {
                                    Image(systemName: "checkmark").foregroundColor(.memberBlue)
                                }
                            }
                        }
                    }
                }

                Section {
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                }

                Section(header: Text("Points")) {
                    HStack {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(points > 1 ? .memberBlue : .textMuted)
                            .font(.system(size: 22))
                            .onTapGesture {
                                if points > 1 { points = max(1, points - 5) }
                            }

                        Spacer()
                        Text("\(points) pts")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Spacer()

                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(points < 500 ? .memberBlue : .textMuted)
                            .font(.system(size: 22))
                            .onTapGesture {
                                if points < 500 { points = min(500, points + 5) }
                            }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Notes (optional)")
                                .foregroundColor(.textMuted)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                    }
                }

                if isParent && assignedIsChild && !availableGoals.isEmpty {
                    Section(header: Text("Reward Goal (optional)")) {
                        Button {
                            rewardGoalId = nil
                        } label: {
                            HStack {
                                Text("None")
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                if rewardGoalId == nil {
                                    Image(systemName: "checkmark").foregroundColor(.memberBlue)
                                }
                            }
                        }
                        ForEach(availableGoals) { goal in
                            Button {
                                rewardGoalId = goal.id
                            } label: {
                                HStack {
                                    Text(goal.titleWithEmoji)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Text("\(goal.pointsCost) pts")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textMuted)
                                    if rewardGoalId == goal.id {
                                        Image(systemName: "checkmark").foregroundColor(.memberBlue)
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Repeat")) {
                    Picker("Repeat", selection: $repeatOption) {
                        ForEach(repeatOptions, id: \.self) { opt in
                            Text(opt.capitalized).tag(opt)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if let err = errorMessage {
                    Section {
                        Text(err).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(isEdit ? "Edit task" : "Add task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("✕") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(title.isEmpty)
                    }
                }
            }
        }
        .task {
            prefill()
            if let family: Family = try? await APIClient.shared.get("/families/mine") {
                members = family.members
                if !assignedToId.isEmpty {
                    await loadGoalsForAssignee(assignedToId)
                }
            }
        }
        .onChange(of: assignedToId) { newId in
            rewardGoalId = nil
            availableGoals = []
            if !newId.isEmpty {
                Task { await loadGoalsForAssignee(newId) }
            }
        }
    }

    private func prefill() {
        if let t = task {
            title = t.title
            assignedToId = t.assignedTo ?? ""
            dueDate = t.dueAt ?? Date()
            points = t.points
            notes = t.notes ?? ""
            repeatOption = t.repeat_ ?? "none"
            rewardGoalId = t.rewardGoalId
        } else {
            assignedToId = authVM.currentProfile?.id ?? ""
        }
    }

    private func loadGoalsForAssignee(_ memberId: String) async {
        guard assignedIsChild else { availableGoals = []; return }
        let goals: [Reward]? = try? await APIClient.shared.get(
            "/rewards",
            params: ["memberId": memberId, "status": "active"]
        )
        availableGoals = goals ?? []
    }

    private func save() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        let body = TaskCreateRequest(
            title: title,
            assignedTo: assignedToId.isEmpty ? nil : assignedToId,
            dueAt: dueDate,
            points: points,
            notes: notes.isEmpty ? nil : notes,
            repeat: repeatOption == "none" ? nil : repeatOption,
            rewardGoalId: rewardGoalId
        )
        do {
            if let t = task {
                let _: DotoTask = try await APIClient.shared.put("/tasks/\(t.id)", body: body)
            } else {
                let _: DotoTask = try await APIClient.shared.post("/tasks", body: body)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
