import SwiftUI

struct ParentEmptyDashboard: View {
    let onAddEvent: () -> Void
    let onAddTask: () -> Void
    let onInvitePartner: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("👋")
                        .font(.system(size: 14))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome to Doto")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.conflictText)
                        Text("Add your first event and task to get started.")
                            .font(.system(size: 11))
                            .foregroundColor(.conflictText)
                    }
                }
                .padding(10)
                .background(Color.conflictBg)
                .cornerRadius(7)
                .padding(.horizontal)

                emptyCTACard(emoji: "📅", title: "Add your first event", subtitle: "Schedule a family event", action: onAddEvent)
                emptyCTACard(emoji: "✅", title: "Assign a task", subtitle: "Create a task for a family member", action: onAddTask)
                emptyCTACard(emoji: "👥", title: "Invite your partner", subtitle: "Share the mental load", action: onInvitePartner)
            }
            .padding(.top, 20)
        }
    }

    private func emptyCTACard(emoji: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji).font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
            }
            .padding(14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundColor(.cardBorder)
            )
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
}
