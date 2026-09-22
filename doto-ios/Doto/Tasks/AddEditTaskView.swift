import SwiftUI

struct TaskCreateRequest: Encodable {
    let title: String
    let description: String?
    let assignedTo: String?
    let priority: String?
    let taskType: String?
    let icon: String?
    let timeOfDay: String?
    let points: Int?
    let rewardGoalId: String?
    let dueDate: String?          // "yyyy-MM-dd"
    let notes: String?
    let repeatRule: String?
    let repeatDays: [Int]?
    let repeatUntil: String?      // "yyyy-MM-dd"
}

struct TaskUpdateRequest: Encodable {
    let title: String?
    let description: String?
    let assignedTo: String?
    let priority: String?
    let taskType: String?
    let icon: String?
    let timeOfDay: String?
    let points: Int?
    let rewardGoalId: String??   // nil = not set, .some(nil) = clear
    let dueDate: String?         // omitted for scope=future (not changeable)
    let notes: String?
    let repeatRule: String?      // omitted for scope=future
    let repeatDays: [Int]??      // omitted for scope=future; .some(nil) clears
    let repeatUntil: String??    // .some(nil) clears the end date
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
    @State private var priority = "medium"
    @State private var taskType: TaskType = .chore
    @State private var selectedIcon: String? = nil
    @State private var showIconPicker = false
    /// Routine-only daily bucket; nil until the parent picks one.
    @State private var timeOfDay: String? = nil
    @State private var showRoutineRepeatConfirm = false
    @State private var routineNoneConfirmed = false
    @State private var recurrence = TaskRecurrence()
    @State private var showRepeatSheet = false
    /// Edit scope chosen for a recurring task (nil until the prompt is answered).
    @State private var scope: TaskScope? = nil
    @State private var showScopeDialog = false
    @State private var rewardGoalId: String? = nil
    @State private var availableGoals: [Reward] = []
    @State private var members: [Profile] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let priorityOptions = ["low", "medium", "high"]
    private var isEdit: Bool { task != nil }
    private var dueWeekday: Int { Calendar.current.component(.weekday, from: dueDate) }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 12) {
                            iconButton
                            TextField("Task name", text: $title)
                        }
                        Text(selectedIcon == nil ? "Tap to add an icon" : "Tap icon to change")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
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

                if taskType == .routine {
                    Section(header: Text("Time of day")) {
                        Picker("Time of day", selection: Binding(
                            get: { timeOfDay ?? "" },
                            set: { timeOfDay = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("Morning").tag("morning")
                            Text("Afternoon").tag("afternoon")
                            Text("Evening").tag("evening")
                        }
                        .pickerStyle(.segmented)
                        if timeOfDay == nil {
                            Text("Pick when this routine happens")
                                .font(.system(size: 11))
                                .foregroundColor(.textMuted)
                        }
                    }
                } else {
                    Section {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                            .disabled(scope == .future)
                    }
                }

                Section(header: Text("Type")) {
                    HStack(spacing: 8) {
                        ForEach(TaskType.allCases, id: \.self) { type in
                            Button {
                                taskType = type
                                if type == .routine && recurrence.frequency == .none {
                                    recurrence.frequency = .daily
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 15))
                                    Text(type.label)
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .foregroundColor(taskType == type ? .white : type.color)
                                .background(taskType == type ? type.color : type.color.opacity(0.12))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(priorityOptions, id: \.self) { opt in
                            Text(opt.capitalized).tag(opt)
                        }
                    }
                    .pickerStyle(.segmented)
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

                Section(header: Text("Reward Goal (optional)")) {
                    if availableGoals.isEmpty {
                        Text("No active goals — set one in Rewards")
                            .font(.system(size: 12))
                            .foregroundColor(.textMuted)
                    } else {
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
                    Button {
                        showRepeatSheet = true
                    } label: {
                        HStack {
                            Text("Repeat")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text(recurrence.summary(dueWeekday: dueWeekday))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.memberBlue)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.textMuted)
                        }
                    }
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
                            .disabled(title.isEmpty || (taskType == .routine && timeOfDay == nil))
                    }
                }
            }
        }
        .sheet(isPresented: $showRepeatSheet) {
            RepeatPickerSheet(recurrence: $recurrence, dueDate: dueDate,
                              frequencyEditable: scope != .future)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showIconPicker) {
            TaskIconPickerView(selected: $selectedIcon)
        }
        .onAppear {
            // Editing an occurrence of a series requires choosing an update scope.
            if task?.isRecurring == true && scope == nil {
                showScopeDialog = true
            }
        }
        .confirmationDialog("Edit recurring task", isPresented: $showScopeDialog, titleVisibility: .visible) {
            Button("This task only") { scope = .this }
            Button("This and future tasks") { scope = .future }
            Button("Cancel", role: .cancel) {
                if scope == nil { dismiss() }
            }
        } message: {
            Text("Apply changes to just this occurrence, or this and all future occurrences?")
        }
        .confirmationDialog("Routine without repeat?", isPresented: $showRoutineRepeatConfirm, titleVisibility: .visible) {
            Button("Keep as Daily") {
                recurrence.frequency = .daily
                routineNoneConfirmed = true
                Task { await save() }
            }
            Button("Yes, just once") {
                routineNoneConfirmed = true
                Task { await save() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Routines usually repeat daily. Create it as a daily routine, or just this once?")
        }
        .task {
            prefill()
            if let family: Family = try? await APIClient.shared.get("/families/mine") {
                members = family.members
            }
            await loadGoals()
        }
    }

    @ViewBuilder
    private var iconButton: some View {
        Button {
            showIconPicker = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                if let symbol = selectedIcon {
                    let color = TaskIconCatalog.color(for: symbol) ?? .memberBlue
                    Image(systemName: TaskIconCatalog.resolve(symbol))
                        .font(.system(size: 24))
                        .foregroundColor(color)
                        .frame(width: 52, height: 52)
                        .background(color.opacity(0.12))
                        .cornerRadius(12)
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(color)
                        .background(Circle().fill(Color.white).padding(2))
                        .offset(x: 4, y: 4)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.textMuted)
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(hex: "#E0C8AE"), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func prefill() {
        if let t = task {
            title = t.title
            selectedIcon = t.icon
            assignedToId = t.assignedTo ?? ""
            dueDate = t.dueDate ?? Date()
            points = t.points
            priority = t.priority ?? "medium"
            taskType = t.type
            notes = t.notes ?? ""
            recurrence = t.recurrence
            rewardGoalId = t.rewardGoalId
            timeOfDay = t.timeOfDay
        } else {
            assignedToId = authVM.currentProfile?.id ?? ""
        }
    }

    private func loadGoals() async {
        let goals: [Reward]? = try? await APIClient.shared.get(
            "/rewards",
            params: ["status": "active"]
        )
        availableGoals = goals ?? []
    }

    private func save() async {
        // Routines are meant to repeat — confirm before creating a one-off.
        if taskType == .routine && recurrence.frequency == .none && !routineNoneConfirmed {
            showRoutineRepeatConfirm = true
            return
        }
        // The API requires a custom rule to include dueDate's day-of-week.
        if recurrence.frequency == .custom { recurrence.weekdays.insert(dueWeekday) }

        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            if let t = task {
                let effectiveScope: TaskScope? = t.isRecurring ? (scope ?? .this) : nil
                // scope=future cannot change dueDate/repeatRule/repeatDays.
                let sendsRuleFields = effectiveScope != .future
                let body = TaskUpdateRequest(
                    title: title,
                    description: notes.isEmpty ? nil : notes,
                    assignedTo: assignedToId.isEmpty ? nil : assignedToId,
                    priority: priority,
                    taskType: taskType.rawValue,
                    icon: selectedIcon,
                    timeOfDay: taskType == .routine ? timeOfDay : nil,
                    points: taskType.earnsPoints ? points : 0,
                    rewardGoalId: rewardGoalId.map { .some($0) } ?? .some(nil),
                    dueDate: sendsRuleFields ? dueDate.apiDateOnly : nil,
                    notes: notes.isEmpty ? nil : notes,
                    repeatRule: sendsRuleFields ? recurrence.apiRepeatRule : nil,
                    repeatDays: sendsRuleFields ? .some(recurrence.apiRepeatDays) : nil,
                    repeatUntil: .some(recurrence.apiRepeatUntil?.apiDateOnly)
                )
                var path = "/tasks/\(t.id)"
                if let effectiveScope { path += "?scope=\(effectiveScope.rawValue)" }
                let _: DotoTask = try await APIClient.shared.put(path, body: body)
            } else {
                let body = TaskCreateRequest(
                    title: title,
                    description: notes.isEmpty ? nil : notes,
                    assignedTo: assignedToId.isEmpty ? nil : assignedToId,
                    priority: priority,
                    taskType: taskType.rawValue,
                    icon: selectedIcon,
                    timeOfDay: taskType == .routine ? timeOfDay : nil,
                    points: taskType.earnsPoints ? points : 0,
                    rewardGoalId: rewardGoalId,
                    dueDate: dueDate.apiDateOnly,
                    notes: notes.isEmpty ? nil : notes,
                    repeatRule: recurrence.apiRepeatRule,
                    repeatDays: recurrence.apiRepeatDays,
                    repeatUntil: recurrence.apiRepeatUntil?.apiDateOnly
                )
                let _: DotoTask = try await APIClient.shared.post("/tasks", body: body)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
