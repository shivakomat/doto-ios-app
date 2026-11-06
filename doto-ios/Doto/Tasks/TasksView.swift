import SwiftUI

struct TasksView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm: TasksViewModel

    init(vm: TasksViewModel = TasksViewModel()) {
        _vm = StateObject(wrappedValue: vm)
    }

    @State private var showAddTask = false
    @State private var showClearConfirm = false
    @State private var selectedTask: DotoTask?
    @State private var taskPendingDelete: DotoTask?
    @State private var typeFilter: TaskType? = nil
    @State private var isSearching = false
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    private var isParent: Bool { authVM.currentProfile?.isParent == true }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private var isSearchFiltering: Bool { isSearching && !trimmedQuery.isEmpty }

    private func applyTypeFilter(_ tasks: [DotoTask]) -> [DotoTask] {
        var result = tasks
        if let typeFilter { result = result.filter { $0.type == typeFilter } }
        if isSearchFiltering { result = result.filter { $0.title.lowercased().contains(trimmedQuery) } }
        return result
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
                .filter { (typeFilter == nil && !isSearchFiltering) || !$0.tasks.isEmpty }
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
            DashboardBackground()

            VStack(spacing: 0) {
                ScreenTitleBar(title: "Tasks", subtitle: "Keep your home running together") {
                    DashboardCircleButton(systemName: isSearching ? "xmark" : "magnifyingglass",
                                          label: isSearching ? "Close search" : "Search tasks") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearching.toggle()
                            if !isSearching { searchText = "" }
                        }
                        searchFocused = isSearching
                    }
                    .disabled(vm.tasks.isEmpty)
                    .opacity(vm.tasks.isEmpty ? 0.5 : 1)

                    if isParent {
                        DashboardAddButton { showAddTask = true }
                    }
                }

                if isSearching { searchField }

                typeChips

                if vm.isLoading && vm.tasks.isEmpty {
                    LoadingView()
                } else if vm.tasks.isEmpty {
                    EmptyStateView(
                        message: "No tasks yet",
                        systemImage: "checkmark.circle",
                        cta: isParent ? "Add one" : nil
                    ) { showAddTask = true }
                } else if memberGroups.isEmpty && routineGroups.isEmpty {
                    EmptyStateView(message: isSearchFiltering
                                       ? "No tasks match \"\(searchText)\""
                                       : "No \(typeFilter?.pluralLabel ?? "tasks") to show",
                                   systemImage: isSearchFiltering ? "magnifyingglass" : (typeFilter?.icon ?? "checkmark.circle"),
                                   cta: nil) {}
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 14) {
                            if !routineGroups.isEmpty {
                                routinesCard
                            }
                            ForEach(memberGroups, id: \.profile.id) { group in
                                memberTaskCard(profile: group.profile, tasks: group.tasks)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 2)
                        .padding(.bottom, 90)
                    }
                    .refreshable { await vm.load() }
                }
            }

            if isParent && vm.hasCompletedTasks {
                FloatingClearButton(count: vm.tasks.filter { $0.isDone }.count,
                                    label: "Clear completed tasks") { showClearConfirm = true }
                    .padding(.trailing, 25)
                    .padding(.bottom, 84)
                    .transition(.scale.combined(with: .opacity))
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
                        .background(Color.dashBlue)
                        .clipShape(Circle())
                        .shadow(color: Color.dashBlue.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
        }
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

    // MARK: - Header pieces

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.dashSubtle)
            TextField("Search tasks", text: $searchText)
                .focused($searchFocused)
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.textMuted)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.dashCardBorder, lineWidth: 1))
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    private var typeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TaskTypeChip(label: "All", color: .dashNavy, isSelected: typeFilter == nil) {
                    typeFilter = nil
                }
                ForEach(TaskType.allCases, id: \.self) { type in
                    TaskTypeChip(label: type.label, icon: type.icon, color: type.color,
                                 isSelected: typeFilter == type) {
                        typeFilter = type
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 2)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Cards

    @ViewBuilder
    private func memberTaskCard(profile: Profile, tasks: [DotoTask]) -> some View {
        let (done, total) = doneCount(tasks: tasks)
        let accent = Color(hex: profile.color)

        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    AvatarView(name: profile.displayName, color: profile.color, size: 32)
                    Text(profile.displayName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.dashNavy)
                    Spacer()
                    Text("\(done) / \(total) done")
                        .font(.system(size: 13))
                        .foregroundColor(.dashSubtle)
                }
                progressBar(accent, progress: listProgress(tasks: tasks))
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)

            taskRows(tasks, profile: profile, showAssignee: false)
        }
        .dashboardCard(radius: 16, fill: accent.opacity(0.07), border: accent.opacity(0.25))
    }

    /// Family-wide routines grouped by time of day, above the member cards.
    @ViewBuilder
    private var routinesCard: some View {
        let accent = TaskType.routine.color
        let (done, total) = doneCount(tasks: routineTasks)

        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: TaskType.routine.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accent)
                        .frame(width: 32, height: 32)
                        .background(accent.opacity(0.16))
                        .clipShape(Circle())
                    Text("Routines")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.dashNavy)
                    Spacer()
                    Text("\(done) / \(total) done")
                        .font(.system(size: 13))
                        .foregroundColor(.dashSubtle)
                }
                progressBar(accent, progress: listProgress(tasks: routineTasks))
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 6)

            ForEach(routineGroups, id: \.key) { group in
                HStack(spacing: 5) {
                    Image(systemName: routineGroupIcon(group.key))
                        .font(.system(size: 10, weight: .semibold))
                    Text(group.key.capitalized)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.dashSubtle)
                .padding(.horizontal, 14)
                .padding(.top, 6)

                taskRows(group.tasks, profile: nil, showAssignee: true, resolveProfile: true)
            }
            Spacer().frame(height: 4)
        }
        .dashboardCard(radius: 16, fill: accent.opacity(0.07), border: accent.opacity(0.25))
    }

    private func progressBar(_ color: Color, progress: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.2))
                Capsule()
                    .fill(color)
                    .frame(width: max(geo.size.width * progress, progress > 0 ? 6 : 0))
            }
        }
        .frame(height: 6)
    }

    private func taskRows(_ tasks: [DotoTask], profile: Profile?, showAssignee: Bool, resolveProfile: Bool = false) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(tasks.enumerated()), id: \.element.id) { idx, task in
                taskRow(task: task,
                        profile: resolveProfile ? vm.members.first { $0.id == task.assignedTo } : profile,
                        showAssignee: showAssignee)
                    .overlay(alignment: .top) {
                        Rectangle().fill(Color.dashCardBorder.opacity(0.9)).frame(height: 1)
                            .padding(.horizontal, 14)
                            .opacity(idx == 0 ? 0 : 1)
                    }
            }
        }
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
        HStack(spacing: 12) {
            Button {
                if !task.isDone && !task.isFutureOccurrence {
                    Task { await vm.completeTask(task) }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(task.isDone ? Color.dashGreen : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(task.isDone ? Color.dashGreen : Color(hex: "#C5CCD9"), lineWidth: 1.5)
                        )
                        .frame(width: 22, height: 22)
                    if task.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
                .opacity(task.isFutureOccurrence ? 0.35 : 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isDone ? "\(task.title), done" : "Complete \(task.title)")

            Button {
                selectedTask = task
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: task.resolvedIcon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(task.iconColor)
                        .frame(width: 38, height: 38)
                        .background(task.iconColor.opacity(0.14))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(task.title)
                                .font(.system(size: 15, weight: .semibold))
                                .strikethrough(task.isDone)
                                .foregroundColor(task.isDone ? .dashSubtle : (task.isOverdue ? .dashRedText : .dashNavy))
                                .lineLimit(1)
                            if task.isRecurring {
                                Image(systemName: "repeat")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.textMuted)
                            }
                        }
                        metaLine(task: task)
                        if showAssignee, let profile {
                            HStack(spacing: 4) {
                                AvatarView(name: profile.displayName, color: profile.color, size: 14)
                                Text(profile.displayName)
                                    .font(.system(size: 11))
                                    .foregroundColor(.dashSubtle)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if task.type.earnsPoints {
                pointsBadge(task: task)
            } else {
                typeBadge(task: task)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contextMenu {
            if !task.isDone && !task.isFutureOccurrence {
                Button {
                    Task { await vm.completeTask(task) }
                } label: {
                    Label("Mark done", systemImage: "checkmark")
                }
            }
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
                .font(.system(size: 12))
                .foregroundColor(.dashSubtle)
        } else if task.isOverdue {
            let suffix = task.isRecurring
                ? " · \(task.recurrence.listSummary(dueWeekday: task.dueWeekday))"
                : ""
            Text("Overdue\(suffix)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.dashRedText)
        } else if task.isRecurring {
            let summary = task.recurrence.listSummary(dueWeekday: task.dueWeekday)
            let cal = Calendar.current
            let dayAfterTomorrow = cal.date(byAdding: .day, value: 2, to: cal.startOfDay(for: Date()))!
            if task.dueDate.map({ cal.isDateInTomorrow($0) }) == true {
                Text("Tomorrow · \(summary)")
                    .font(.system(size: 12))
                    .foregroundColor(.dueTodayText)
            } else if let due = task.dueDate, due >= dayAfterTomorrow {
                // Upcoming representative of a series that hasn't started yet
                Text("Starts \(due.shortDate) · \(summary)")
                    .font(.system(size: 12))
                    .foregroundColor(.dashSubtle)
            } else {
                Text(summary)
                    .font(.system(size: 12))
                    .foregroundColor(.dashSubtle)
            }
        } else if let due = task.dueDate {
            let label = due.relativeDue
            let relative = ["Today", "Tomorrow", "Yesterday"].contains(label)
            Text("Due \(relative ? label.lowercased() : label)")
                .font(.system(size: 12))
                .foregroundColor(.dashSubtle)
        } else {
            EmptyView()
        }
    }

    /// Always-visible "+N pts" badge — amber while pending, green once done.
    @ViewBuilder
    private func pointsBadge(task: DotoTask) -> some View {
        DashboardBadge(
            text: "+\(task.points) pts",
            foreground: task.isDone ? .pointsDoneText : .pointsPendingText,
            background: task.isDone ? .pointsDoneBg : Color(hex: "#FDEBD9")
        )
    }

    /// Type icon badge shown in place of points for non-chore tasks.
    @ViewBuilder
    private func typeBadge(task: DotoTask) -> some View {
        Image(systemName: task.type.icon)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(task.type.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(task.type.color.opacity(0.15))
            .clipShape(Capsule())
    }
}

/// Rounded filter chip used by the task-type filter row.
private struct TaskTypeChip: View {
    let label: String
    var icon: String? = nil
    var color: Color = .dashNavy
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color.opacity(isSelected ? 0.22 : 0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(isSelected ? 0.6 : 0), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}
