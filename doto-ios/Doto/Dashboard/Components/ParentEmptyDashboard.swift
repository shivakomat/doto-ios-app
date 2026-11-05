import SwiftUI

struct ParentEmptyDashboard: View {
    let onAddEvent: () -> Void
    let onAddTask: () -> Void
    let onInvitePartner: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Text("👋")
                        .font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome to Doto")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.dashNavy)
                        Text("Add your first event and task to get started.")
                            .font(.system(size: 13))
                            .foregroundColor(.dashSubtle)
                    }
                    Spacer()
                }
                .padding(14)
                .dashboardCard(radius: 16, fill: Color(hex: "#FEF6DC"), border: Color(hex: "#F6DF93"))

                emptyCTACard(icon: "calendar", color: .dashBlue, title: "Add your first event", subtitle: "Schedule a family event", action: onAddEvent)
                emptyCTACard(icon: "checkmark.circle.fill", color: .dashGreen, title: "Assign a task", subtitle: "Create a task for a family member", action: onAddTask)
                emptyCTACard(icon: "person.2.fill", color: Color(hex: "#7A5AF8"), title: "Invite your partner", subtitle: "Share the mental load", action: onInvitePartner)
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
    }

    private func emptyCTACard(icon: String, color: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.14))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.dashNavy)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.dashSubtle)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textMuted)
            }
            .padding(14)
            .dashboardCard(radius: 16)
        }
        .buttonStyle(.plain)
    }
}
