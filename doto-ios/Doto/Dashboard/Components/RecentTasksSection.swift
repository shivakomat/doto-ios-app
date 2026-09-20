import SwiftUI

struct RecentTasksSection: View {
    let tasks: [DashboardTask]
    let onTaskTap: ((DashboardTask) -> Void)?
    var onComplete: ((DashboardTask) -> Void)? = nil
    var completingIds: Set<String> = []
    /// Ids of recurring occurrences due tomorrow or later — checkbox is locked.
    var lockedIds: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recently assigned")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textPrimary)

            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    RecentTaskRow(
                        task: task,
                        isCompleting: completingIds.contains(task.id),
                        isLocked: lockedIds.contains(task.id),
                        onTap: onTaskTap,
                        onComplete: {
                            if !task.isDone && !lockedIds.contains(task.id) { onComplete?(task) }
                        }
                    )
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
        }
    }
}

struct RecentTaskRow: View {
    let task: DashboardTask
    let isCompleting: Bool
    var isLocked: Bool = false
    let onTap: ((DashboardTask) -> Void)?
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onComplete) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(task.isDone ? Color(hex: "#1D9E75") : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(task.isDone ? Color(hex: "#1D9E75") : Color.cardBorder, lineWidth: 2)
                        )
                        .frame(width: 16, height: 16)

                    if isCompleting {
                        ProgressView().scaleEffect(0.4)
                    } else if task.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .opacity(isLocked ? 0.35 : 1)
            }
            .buttonStyle(.plain)
            .disabled(isLocked || task.isDone)

            if let color = task.assigneeColor, let name = task.assigneeName {
                AvatarView(name: name, color: color, size: 18)
            }

            Image(systemName: task.resolvedIcon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(task.iconColor)

            Text(task.title)
                .font(.system(size: 12))
                .foregroundColor(
                    task.isDone    ? .textMuted :
                    task.isOverdue ? Color(hex: "#E24B4A") : .textPrimary
                )
                .strikethrough(task.isDone, color: .textMuted)
                .lineLimit(1)

            Spacer()

            if task.isDone && task.type.earnsPoints {
                Text("+\(task.points) pts")
                    .font(.system(size: 9, weight: .medium))
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
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?(task)
        }
    }
}
