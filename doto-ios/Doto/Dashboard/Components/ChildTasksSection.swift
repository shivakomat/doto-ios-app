import SwiftUI

struct ChildTasksSection: View {
    let tasks: [ChildTask]
    let onComplete: (ChildTask) -> Void
    let completingIds: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My tasks today")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textPrimary)

            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    ChildTaskRow(
                        task: task,
                        isCompleting: completingIds.contains(task.id),
                        onTap: { if !task.isDone { onComplete(task) } }
                    )
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
        }
    }
}

struct ChildTaskRow: View {
    let task: ChildTask
    let isCompleting: Bool
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
            }
            .buttonStyle(.plain)

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

            if task.isDone {
                Text("+\(task.points) pts")
                    .font(.system(size: 10, weight: .medium))
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
    }
}
