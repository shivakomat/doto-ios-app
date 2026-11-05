import SwiftUI

struct ChildTasksSection: View {
    let tasks: [ChildTask]
    let onComplete: (ChildTask) -> Void
    let completingIds: Set<String>
    /// Ids of recurring occurrences due tomorrow or later — checkbox is locked.
    var lockedIds: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !routineGroups.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    DashboardSectionHeader(title: "Routines")
                    ForEach(routineGroups, id: \.key) { group in
                        HStack(spacing: 5) {
                            Image(systemName: routineGroupIcon(group.key))
                                .font(.system(size: 10, weight: .semibold))
                            Text("\(group.key.capitalized) (\(group.tasks.count))")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.dashSubtle)
                        taskCard(group.tasks)
                    }
                }
            }

            if !regularTasks.isEmpty || routineGroups.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("My tasks today")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.dashNavy)
                        if !typeSummary.isEmpty {
                            Text("· \(typeSummary)")
                                .font(.system(size: 13))
                                .foregroundColor(.dashSubtle)
                                .lineLimit(1)
                        }
                    }
                    taskCard(regularTasks)
                }
            }
        }
    }

    private func taskCard(_ list: [ChildTask]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(list.enumerated()), id: \.element.id) { idx, task in
                ChildTaskRow(
                    task: task,
                    isCompleting: completingIds.contains(task.id),
                    isLocked: lockedIds.contains(task.id),
                    showDivider: idx < list.count - 1,
                    onTap: { if !task.isDone && !lockedIds.contains(task.id) { onComplete(task) } }
                )
            }
        }
        .dashboardCard()
    }

    private var routineTasks: [ChildTask] { tasks.filter { $0.type == .routine } }
    private var regularTasks: [ChildTask] { tasks.filter { $0.type != .routine } }

    private var routineGroups: [(key: String, tasks: [ChildTask])] {
        ["morning", "afternoon", "evening"]
            .map { key in (key, routineTasks.filter { ($0.timeOfDay ?? "morning") == key }) }
            .filter { !$0.tasks.isEmpty }
    }

    private func routineGroupIcon(_ key: String) -> String {
        switch key {
        case "morning":   return "sunrise.fill"
        case "afternoon": return "sun.max.fill"
        default:          return "moon.fill"
        }
    }

    /// e.g. "2 chores · 1 homework" — counts incomplete tasks by type.
    private var typeSummary: String {
        let counts = tasks.filter { !$0.isDone }
            .reduce(into: [TaskType: Int]()) { $0[$1.type, default: 0] += 1 }
        return TaskType.allCases.compactMap { type in
            counts[type].map { "\($0) \($0 == 1 ? type.label.lowercased() : type.pluralLabel)" }
        }.joined(separator: " · ")
    }
}

struct ChildTaskRow: View {
    let task: ChildTask
    let isCompleting: Bool
    var isLocked: Bool = false
    var showDivider: Bool = true
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(task.isDone ? Color.dashGreen : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(task.isDone ? Color.dashGreen : Color(hex: "#C5CCD9"), lineWidth: 1.5)
                        )
                        .frame(width: 24, height: 24)

                    if isCompleting {
                        ProgressView().scaleEffect(0.5)
                    } else if task.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
                .opacity(isLocked ? 0.35 : 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isDone ? "\(task.title), done" : "Complete \(task.title)")

            Image(systemName: task.resolvedIcon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(task.iconColor)
                .frame(width: 38, height: 38)
                .background(task.iconColor.opacity(0.14))
                .clipShape(Circle())

            Text(task.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(
                    task.isDone    ? .dashSubtle :
                    task.isOverdue ? .dashRedText :
                    .dashNavy
                )
                .strikethrough(task.isDone, color: .textMuted)
                .lineLimit(1)

            Spacer(minLength: 8)

            badge
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            if showDivider {
                Rectangle().fill(Color.dashCardBorder).frame(height: 1).padding(.horizontal, 14)
            }
        }
    }

    @ViewBuilder
    private var badge: some View {
        if task.isDone && task.type.earnsPoints {
            DashboardBadge(text: "+\(task.points) pts", foreground: .doneText, background: .doneBg)
        } else if task.isDone {
            // Completed non-chore — show the type badge instead of points.
            Image(systemName: task.type.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(task.type.color)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(task.type.color.opacity(0.15))
                .clipShape(Capsule())
        } else if task.isOverdue {
            DashboardBadge(text: "Overdue", foreground: .dashRedText, background: .dashRedTint)
        } else if task.dueDate.map({ Calendar.current.isDateInToday($0) }) == true {
            DashboardBadge(text: "Today", foreground: .dashBlue, background: .dashBlueTint)
        } else if task.dueDate.map({ Calendar.current.isDateInTomorrow($0) }) == true {
            DashboardBadge(text: "Tomorrow", foreground: .textSecondary, background: Color(hex: "#EEF1F6"))
        } else if let due = task.dueDate,
                  due >= Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: Date()))! {
            DashboardBadge(text: "Upcoming", foreground: .textSecondary, background: Color(hex: "#EEF1F6"))
        }
    }
}
