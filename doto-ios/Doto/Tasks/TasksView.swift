import SwiftUI

struct TasksView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = TasksViewModel()

    @State private var showAddTask = false
    @State private var selectedTask: DotoTask?

    private var isParent: Bool { authVM.currentProfile?.isParent == true }

    private var memberGroups: [(profile: Profile, tasks: [DotoTask])] {
        guard let currentProfile = authVM.currentProfile else { return [] }
        if isParent {
            let others = vm.members
                .filter { $0.id != currentProfile.id }
                .sorted { $0.displayName < $1.displayName }
            let ordered = [currentProfile] + others
            return ordered.map { m in (profile: m, tasks: sortedTasks(vm.tasksForMember(m.id))) }
        } else {
            return [(currentProfile, sortedTasks(vm.tasksForMember(currentProfile.id)))]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            DotoNavHeader(title: "Tasks", trailing: {
                AnyView(
                    isParent ? AnyView(NavAddButton { showAddTask = true }) : AnyView(EmptyView())
                )
            })

            if vm.isLoading && vm.tasks.isEmpty {
                LoadingView()
            } else if vm.tasks.isEmpty {
                EmptyStateView(
                    message: "No tasks yet",
                    systemImage: "checkmark.circle",
                    cta: isParent ? "Add one" : nil
                ) { showAddTask = true }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
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
        .background(Color.screenBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await vm.load() }
        .sheet(isPresented: $showAddTask, onDismiss: { Task { await vm.load() } }) {
            AddEditTaskView(task: nil)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task, onUpdate: { Task { await vm.load() } })
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
            switch ($0.dueAt, $1.dueAt) {
            case let (a?, b?): return a < b
            case (nil, _?):   return false
            case (_?, nil):   return true
            case (nil, nil):  return false
            }
        }
        let done       = tasks.filter { $0.isDone  }
        return incomplete + done
    }

    private var weekBounds: (start: Date, end: Date) { Date().weekBounds }

    private func weekProgress(tasks: [DotoTask]) -> Double {
        let (weekStart, weekEnd) = weekBounds
        let weekTasks = tasks.filter {
            guard let dueAt = $0.dueAt else { return false }
            return dueAt >= weekStart && dueAt < weekEnd
        }
        guard !weekTasks.isEmpty else { return 0 }
        let done = weekTasks.filter { $0.isDone }.count
        return Double(done) / Double(weekTasks.count)
    }

    private func doneCountThisWeek(tasks: [DotoTask]) -> (done: Int, total: Int) {
        let (weekStart, weekEnd) = weekBounds
        let weekTasks = tasks.filter {
            guard let dueAt = $0.dueAt else { return false }
            return dueAt >= weekStart && dueAt < weekEnd
        }
        return (weekTasks.filter { $0.isDone }.count, weekTasks.count)
    }

    @ViewBuilder
    private func memberTaskCard(profile: Profile, tasks: [DotoTask]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let (done, total) = doneCountThisWeek(tasks: tasks)
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
                        .frame(width: geo.size.width * weekProgress(tasks: tasks), height: 6)
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

    @ViewBuilder
    private func taskRow(task: DotoTask, profile: Profile) -> some View {
        HStack(spacing: 10) {
            Button {
                if !task.isDone {
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
            }

            Button {
                selectedTask = task
            } label: {
                Text(task.title)
                    .font(.system(size: 13))
                    .strikethrough(task.isDone)
                    .foregroundColor(task.isDone ? .textMuted : (task.isOverdue ? Color(hex: "#E24B4A") : .textPrimary))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            statusBadge(task: task)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !task.isDone {
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
                    Task { await vm.deleteTask(task) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    private func statusBadge(task: DotoTask) -> some View {
        if task.isDone {
            Text("+\(task.points) pts")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.doneText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.doneBg)
                .cornerRadius(4)
        } else if task.isOverdue {
            Text("Overdue")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "#E24B4A"))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.overdueBg)
                .cornerRadius(4)
        } else if task.isDueToday {
            Text("Today")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.dueTodayText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.dueTodayBg)
                .cornerRadius(4)
        } else {
            EmptyView()
        }
    }
}
