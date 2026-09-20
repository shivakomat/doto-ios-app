import SwiftUI

struct TasksView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = TasksViewModel()

    @State private var showAddTask = false
    @State private var showClearConfirm = false
    @State private var selectedTask: DotoTask?
    @State private var taskPendingDelete: DotoTask?
    @State private var typeFilter: TaskType? = nil

    private var isParent: Bool { authVM.currentProfile?.isParent == true }

    private func applyTypeFilter(_ tasks: [DotoTask]) -> [DotoTask] {
        guard let typeFilter else { return tasks }
        return tasks.filter { $0.type == typeFilter }
    }

    private var memberGroups: [(profile: Profile, tasks: [DotoTask])] {
        guard let currentProfile = authVM.currentProfile else { return [] }
        if isParent {
            let others = vm.members
                .filter { $0.id != currentProfile.id }
                .sorted { $0.displayName < $1.displayName }
            let ordered = [currentProfile] + others
            return ordered
                .map { m in (profile: m, tasks: sortedTasks(applyTypeFilter(vm.tasksForMember(m.id).filter { $0.type != .routine }))) }
                .filter { typeFilter == nil || !$0.tasks.isEmpty }
        } else {
            return [(currentProfile, sortedTasks(applyTypeFilter(vm.tasksForMember(currentProfile.id).filter { $0.type != .routine })))]
        }
    }

    /// Family-visible routines (own tasks only for a child), honoring the type filter.
    private var routineTasks: [DotoTask] {
        guard let me = authVM.currentProfile else { return [] }
        let profiles: [Profile]
        if isParent {
            let others = vm.members
                .filter { $0.id != me.id }
                .sorted { $0.displayName < $1.displayName }
            profiles = [me] + others
        } else {
            profiles = [me]
        }
        let all = profiles.flatMap { vm.tasksForMember($0.id) }
        return sortedTasks(applyTypeFilter(all.filter { $0.type == .routine }))
    }

    /// Routines bucketed into morning / afternoon / evening for the top section.
    private var routineGroups: [(key: String, tasks: [DotoTask])] {
        ["morning", "afternoon", "evening"]
            .map { key in (key, routineTasks.filter { ($0.timeOfDay ?? "morning") == key }) }
            .filter { !$0.tasks.isEmpty }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                DotoNavHeader(title: "Tasks", trailing: {
                    AnyView(HStack(spacing: 12) {
                        // Clear completed — parent only, only when completed tasks exist
                        if isParent && vm.hasCompletedTasks {
                            Button {
                                showClearConfirm = true
                            } label: {
                                Text("Clear done")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textMuted)
                            }
                        }
                        // Add button — parent only
                        if isParent {
                            NavAddButton { showAddTask = true }
                        }
                    })
                })

                // Type filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        TaskTypeChip(label: "All", color: .memberBlue, isSelected: typeFilter == nil) {
                            typeFilter = nil
                        }
                        ForEach(TaskType.allCases, id: \.self) { type in
                            TaskTypeChip(label: type.label, icon: type.icon, color: type.color,
                                         isSelected: typeFilter == type) {
                                typeFilter = type
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                if vm.isLoading && vm.tasks.isEmpty {
                    LoadingView()
                } else if vm.tasks.isEmpty {
                    EmptyStateView(
                        message: "No tasks yet",
                        systemImage: "checkmark.circle",
                        cta: isParent ? "Add one" : nil
                    ) { showAddTask = true }
                } else if memberGroups.isEmpty && routineGroups.isEmpty {
                    EmptyStateView(message: "No \(typeFilter?.pluralLabel ?? "tasks") to show",
                                   systemImage: typeFilter?.icon ?? "checkmark.circle",
                                   cta: nil) {}
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if !routineGroups.isEmpty {
                                routinesCard
                            }
                            ForEach(memberGroups, id: \.profile.id) { group in
                                memberTaskCard(profile: group.profile, tasks: group.tasks)
                            }
                        }
                        .padding()
                        .padding(.bottom, 40)
                    }
                    .refreshable { await vm.load() }
                }
            }

            // FAB for adding tasks (parent only)
            if isParent {
                Button {
                    showAddTask = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.memberBlue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(20)
            }
        }
        .background(Color.screenBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await vm.load() }
        .sheet(isPresented: $showAddTask, onDismiss: { Task { await vm.load() } }) {
            AddEditTaskView(task: nil)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task, onUpdate: { Task { await vm.load() } })
        }
        .confirmationDialog(
            "Clear completed tasks?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear all completed", role: .destructive) {
                Task { await vm.clearCompleted() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes all completed tasks for the whole family. This cannot be undone.")
        }
        .confirmationDialog(
            "Delete recurring task",
            isPresented: Binding(get: { taskPendingDelete != nil }, set: { if !$0 { taskPendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("This task only", role: .destructive) {
                if let task = taskPendingDelete {
                    Task { await vm.deleteTask(task, scope: .this) }
                }
            }
            Button("This and future tasks", role: .destructive) {
                if let task = taskPendingDelete {
                    Task { await vm.deleteTask(task, scope: .future) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\"\(taskPendingDelete?.title ?? "")\" repeats. Delete just this occurrence, or this and all future occurrences?")
        }
        .alert("Something went wrong",
               isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private func sortedTasks(_ tasks: [DotoTask]) -> [DotoTask] {
        let incomplete = tasks.filter { !$0.isDone }.sorted {
            switch ($0.dueDate, $1.dueDate) {
            case let (a?, b?): return a < b
            case (nil, _?):   return false
            case (_?, nil):   return true
            case (nil, nil):  return false
            }
        }
        let done       = tasks.filter { $0.isDone  }
        return incomplete + done
    }

    private func listProgress(tasks: [DotoTask]) -> Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter { $0.isDone }.count) / Double(tasks.count)
    }

    private func doneCount(tasks: [DotoTask]) -> (done: Int, total: Int) {
        (tasks.filter { $0.isDone }.count, tasks.count)
    }

    @ViewBuilder
    private func memberTaskCard(profile: Profile, tasks: [DotoTask]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let (done, total) = doneCount(tasks: tasks)
            HStack(spacing: 8) {
                AvatarView(name: profile.displayName, color: profile.color, size: 20)
                Text(profile.displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: profile.color))
                Spacer()
                Text("\(done) / \(total) done")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: profile.color))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: profile.color).opacity(0.2))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: profile.color))
                        .frame(width: geo.size.width * listProgress(tasks: tasks), height: 6)
                }
            }
            .frame(height: 6)

            ForEach(tasks) { task in
                taskRow(task: task, profile: profile)
            }
        }
        .padding(12)
        .memberCardBackground(color: profile.color)
    }

    /// Family-wide routines grouped by time of day, above the member cards.
    @ViewBuilder
    private var routinesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: TaskType.routine.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text("Routines")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                let (done, total) = doneCount(tasks: routineTasks)
                Text("\(done) / \(total) done")
                    .font(.system(size: 11))
            }
            .foregroundColor(.memberBlue)

            ForEach(routineGroups, id: \.key) { group in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: routineGroupIcon(group.key))
                            .font(.system(size: 9, weight: .semibold))
                        Text(group.key.capitalized)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.textMuted)
                    ForEach(group.tasks) { task in
                        taskRow(task: task,
                                profile: vm.members.first { $0.id == task.assignedTo },
                                showAssignee: true)
                    }
                }
            }
        }
        .padding(12)
        .memberCardBackground(color: "#185FA5")
    }

    private func routineGroupIcon(_ key: String) -> String {
        switch key {
        case "morning":   return "sunrise.fill"
        case "afternoon": return "sun.max.fill"
        default:          return "moon.fill"
        }
    }

    @ViewBuilder
    private func taskRow(task: DotoTask, profile: Profile?, showAssignee: Bool = false) -> some View {
        HStack(spacing: 10) {
            Button {
                if !task.isDone && !task.isFutureOccurrence {
                    Task { await vm.completeTask(task) }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(task.isDone ? Color.clear : Color(hex: "#CBD5E1"), lineWidth: 1.5)
                        .frame(width: 14, height: 14)
                    if task.isDone {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.doneText)
                            .frame(width: 14, height: 14)
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .opacity(task.isFutureOccurrence ? 0.35 : 1)
            }
            .disabled(task.isDone || task.isFutureOccurrence)

            Button {
                selectedTask = task
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Image(systemName: task.resolvedIcon)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(task.iconColor)
                        Text(task.title)
                            .font(.system(size: 13))
                            .strikethrough(task.isDone)
                            .foregroundColor(task.isDone ? .textMuted : (task.isOverdue ? Color(hex: "#E24B4A") : .textPrimary))
                        if task.isRecurring {
                            Image(systemName: "repeat")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.textMuted)
                        }
                    }
                    metaLine(task: task)
                    if showAssignee, let profile {
                        HStack(spacing: 4) {
                            AvatarView(name: profile.displayName, color: profile.color, size: 12)
                            Text(profile.displayName)
                                .font(.system(size: 9))
                                .foregroundColor(.textMuted)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if task.type.earnsPoints {
                pointsBadge(task: task)
            } else {
                typeBadge(task: task)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !task.isDone && !task.isFutureOccurrence {
                Button {
                    Task { await vm.completeTask(task) }
                } label: {
                    Label("Done", systemImage: "checkmark")
                }
                .tint(.green)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if isParent {
                Button(role: .destructive) {
                    if task.isRecurring {
                        taskPendingDelete = task
                    } else {
                        Task { await vm.deleteTask(task) }
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    /// Subtitle under the title: "Completed at …", "Repeats …", or the due state.
    @ViewBuilder
    private func metaLine(task: DotoTask) -> some View {
        if task.isDone, let label = task.completedTimeLabel {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.doneText)
        } else if task.isOverdue {
            let suffix = task.isRecurring
                ? " · \(task.recurrence.listSummary(dueWeekday: task.dueWeekday))"
                : ""
            Text("Overdue\(suffix)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "#E24B4A"))
        } else if task.isRecurring {
            let summary = task.recurrence.listSummary(dueWeekday: task.dueWeekday)
            let cal = Calendar.current
            let dayAfterTomorrow = cal.date(byAdding: .day, value: 2, to: cal.startOfDay(for: Date()))!
            if task.dueDate.map({ cal.isDateInTomorrow($0) }) == true {
                Text("Tomorrow · \(summary)")
                    .font(.system(size: 10))
                    .foregroundColor(.dueTodayText)
            } else if let due = task.dueDate, due >= dayAfterTomorrow {
                // Upcoming representative of a series that hasn't started yet
                Text("Starts \(due.shortDate) · \(summary)")
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
            } else {
                Text(summary)
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
            }
        } else if let due = task.dueDate {
            let label = due.relativeDue
            let relative = ["Today", "Tomorrow", "Yesterday"].contains(label)
            Text("Due \(relative ? label.lowercased() : label)")
                .font(.system(size: 10))
                .foregroundColor(.textSecondary)
        } else {
            EmptyView()
        }
    }

    /// Always-visible "+N pts" badge — amber while pending, green once done.
    @ViewBuilder
    private func pointsBadge(task: DotoTask) -> some View {
        Text("+\(task.points) pts")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(task.isDone ? .pointsDoneText : .pointsPendingText)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(task.isDone ? Color.pointsDoneBg : Color.pointsPendingBg)
            .cornerRadius(4)
    }

    /// Type icon badge shown in place of points for non-chore tasks.
    @ViewBuilder
    private func typeBadge(task: DotoTask) -> some View {
        Image(systemName: task.type.icon)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(task.type.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(task.type.color.opacity(0.15))
            .cornerRadius(4)
    }
}

/// Small rounded filter chip used by the task-type filter row.
private struct TaskTypeChip: View {
    let label: String
    var icon: String? = nil
    var color: Color = .memberBlue
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? color : color.opacity(0.12))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
