import SwiftUI

struct RecentTasksSection: View {
    let tasks: [DashboardTask]
    let onTaskTap: ((DashboardTask) -> Void)?
    var onComplete: ((DashboardTask) -> Void)? = nil
    var completingIds: Set<String> = []

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
                        onTap: onTaskTap,
                        onComplete: { if !task.isDone { onComplete?(task) } }
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
            }
            .buttonStyle(.plain)

            if let color = task.assigneeColor, let name = task.assigneeName {
                AvatarView(name: name, color: color, size: 18)
            }

            Text(task.title)
                .font(.system(size: 12))
                .foregroundColor(
                    task.isDone    ? .textMuted :
                    task.isOverdue ? Color(hex: "#E24B4A") : .textPrimary
                )
                .strikethrough(task.isDone, color: .textMuted)
                .lineLimit(1)

            Spacer()

            if task.isDone {
                Text("+\(task.points) pts")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color(hex: "#1D9E75"))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.doneBg)
                    .cornerRadius(4)
            } else if task.isOverdue {
                Text("Overdue")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.overdueText)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.overdueBg)
                    .cornerRadius(4)
            } else if Calendar.current.isDateInToday(task.dueAt) {
                Text("Today")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.conflictText)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.conflictBg)
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
