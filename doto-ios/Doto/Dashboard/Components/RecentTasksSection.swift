import SwiftUI

struct RecentTasksSection: View {
    let tasks: [DashboardTask]
    let onTaskTap: ((DashboardTask) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recently assigned")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textPrimary)

            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    RecentTaskRow(task: task, onTap: onTaskTap)
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
    let onTap: ((DashboardTask) -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox — not interactive from dashboard (navigate to Tasks instead)
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.cardBorder, lineWidth: 2)
                .frame(width: 16, height: 16)

            // Assignee avatar
            if let color = task.assigneeColor, let name = task.assigneeName {
                AvatarView(name: name, color: color, size: 18)
            }

            Text(task.title)
                .font(.system(size: 12))
                .foregroundColor(task.isOverdue ? Color(hex: "#E24B4A") : .textPrimary)
                .lineLimit(1)

            Spacer()

            // Badge
            if task.isOverdue {
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
