import SwiftUI

struct TodaysTasksSection: View {
    let tasks: [DashboardTask]
    var onSeeAll: (() -> Void)? = nil
    let onTaskTap: ((DashboardTask) -> Void)?
    var onComplete: ((DashboardTask) -> Void)? = nil
    var completingIds: Set<String> = []
    /// Ids of recurring occurrences due tomorrow or later — checkbox is locked.
    var lockedIds: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DashboardSectionHeader(
                title: "Today's tasks",
                actionTitle: onSeeAll == nil ? nil : "See all",
                action: onSeeAll
            )

            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    TodayTaskRow(
                        task: task,
                        isCompleting: completingIds.contains(task.id),
                        isLocked: lockedIds.contains(task.id),
                        showDivider: task.id != tasks.last?.id,
                        onTap: onTaskTap,
                        onComplete: {
                            if !task.isDone && !lockedIds.contains(task.id) { onComplete?(task) }
                        }
                    )
                }
            }
            .dashboardCard()
        }
    }
}

struct TodayTaskRow: View {
    let task: DashboardTask
    let isCompleting: Bool
    var isLocked: Bool = false
    var showDivider: Bool = true
    let onTap: ((DashboardTask) -> Void)?
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(task.isDone ? Color.dashGreen : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(task.isDone ? Color.dashGreen : Color(hex: "#C5CCD9"), lineWidth: 1.5)
                        )
                        .frame(width: 20, height: 20)

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
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(task.iconColor)
                .frame(width: 32, height: 32)
                .background(task.iconColor.opacity(0.14))
                .clipShape(Circle())

            Text(task.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(
                    task.isDone    ? .textMuted :
                    task.isOverdue ? .dashRedText : .dashNavy
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
                Rectangle()
                    .fill(Color.dashCardBorder)
                    .frame(height: 1)
                    .padding(.horizontal, 14)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?(task)
        }
    }

    @ViewBuilder
    private var badge: some View {
        if task.isDone && task.type.earnsPoints {
            DashboardBadge(text: "+\(task.points) pts", foreground: .doneText, background: .doneBg)
        } else if task.isDone {
            // Completed non-chore — show the type badge instead of points.
            Image(systemName: task.type.icon)
                .font(.system(size: 11, weight: .semibold))
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
