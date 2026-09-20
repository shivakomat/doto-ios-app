import SwiftUI

struct ChildTasksSection: View {
    let tasks: [ChildTask]
    let onComplete: (ChildTask) -> Void
    let completingIds: Set<String>
    /// Ids of recurring occurrences due tomorrow or later — checkbox is locked.
    var lockedIds: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !routineGroups.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Routines")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    ForEach(routineGroups, id: \.key) { group in
                        HStack(spacing: 5) {
                            Image(systemName: routineGroupIcon(group.key))
                                .font(.system(size: 9, weight: .semibold))
                            Text("\(group.key.capitalized) (\(group.tasks.count))")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.textMuted)
                        VStack(spacing: 0) {
                            ForEach(group.tasks) { task in
                                ChildTaskRow(
                                    task: task,
                                    isCompleting: completingIds.contains(task.id),
                                    isLocked: lockedIds.contains(task.id),
                                    onTap: { if !task.isDone && !lockedIds.contains(task.id) { onComplete(task) } }
                                )
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
                    }
                }
            }

            if !regularTasks.isEmpty || routineGroups.isEmpty {
                HStack(spacing: 6) {
                    Text("My tasks today")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    if !typeSummary.isEmpty {
                        Text("· \(typeSummary)")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                }

                VStack(spacing: 0) {
                    ForEach(regularTasks) { task in
                        ChildTaskRow(
                            task: task,
                            isCompleting: completingIds.contains(task.id),
                            isLocked: lockedIds.contains(task.id),
                            onTap: { if !task.isDone && !lockedIds.contains(task.id) { onComplete(task) } }
                        )
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
            }
        }
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
            counts[type].map { "\($0) \(type.pluralLabel)" }
        }.joined(separator: " · ")
    }
}

struct ChildTaskRow: View {
    let task: ChildTask
    let isCompleting: Bool
    var isLocked: Bool = false
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(task.isDone ? Color(hex: "#1D9E75") : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(task.isDone ? Color(hex: "#1D9E75") : Color.cardBorder, lineWidth: 2)
                        )
                        .frame(width: 18, height: 18)

                    if isCompleting {
                        ProgressView().scaleEffect(0.5)
                    } else if task.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .opacity(isLocked ? 0.35 : 1)
            }
            .buttonStyle(.plain)
            .disabled(isLocked || task.isDone)

            Image(systemName: task.resolvedIcon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(task.iconColor)

            Text(task.title)
                .font(.system(size: 13))
                .foregroundColor(
                    task.isDone    ? .textMuted :
                    task.isOverdue ? Color(hex: "#E24B4A") :
                    .textPrimary
                )
                .strikethrough(task.isDone, color: .textMuted)
                .lineLimit(1)

            Spacer()

            if task.isDone && task.type.earnsPoints {
                Text("+\(task.points) pts")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "#1D9E75"))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.doneBg)
                    .cornerRadius(4)
            } else if task.isDone {
                // Completed non-chore — show the type badge instead of points.
                Image(systemName: task.type.icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(task.type.color)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(task.type.color.opacity(0.15))
                    .cornerRadius(4)
            } else if task.isOverdue {
                Text("Overdue")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.overdueText)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.overdueBg)
                    .cornerRadius(4)
            } else if task.dueDate.map({ Calendar.current.isDateInToday($0) }) == true {
                Text("Today")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.conflictText)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.conflictBg)
                    .cornerRadius(4)
            } else if task.dueDate.map({ Calendar.current.isDateInTomorrow($0) }) == true {
                Text("Tomorrow")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.cardBorder)
                    .cornerRadius(4)
            } else if let due = task.dueDate,
                      due >= Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: Date()))! {
                Text("Upcoming")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.cardBorder.opacity(0.5))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(Divider().frame(maxWidth: .infinity), alignment: .bottom)
    }
}
