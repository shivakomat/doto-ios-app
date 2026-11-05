import SwiftUI

struct FABBottomSheet: View {
    @Binding var showAddEvent: Bool
    @Binding var showAddTask: Bool
    @Binding var showAddItem: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DashboardBackground(showLandscape: false)

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.dashCardBorder)
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 14)

                Text("Create new")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.dashNavy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                VStack(spacing: 0) {
                    fabRow(icon: "calendar", color: .dashBlue, title: "Add event") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showAddEvent = true }
                    }
                    Rectangle().fill(Color.dashCardBorder).frame(height: 1).padding(.leading, 66)
                    fabRow(icon: "checkmark.circle.fill", color: .dashGreen, title: "Add task") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showAddTask = true }
                    }
                    Rectangle().fill(Color.dashCardBorder).frame(height: 1).padding(.leading, 66)
                    fabRow(icon: "cart.fill", color: Color(hex: "#F2711C"), title: "Add shopping item") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showAddItem = true }
                    }
                }
                .dashboardCard(radius: 16)
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .presentationDetents([.height(300)])
    }

    private func fabRow(icon: String, color: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.14))
                    .clipShape(Circle())
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.dashNavy)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
