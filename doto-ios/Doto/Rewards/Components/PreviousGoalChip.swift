// PreviousGoalChip.swift - Doto Rewards Component
import SwiftUI

struct PreviousGoalChip: View {
    let goal: Reward
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(goal.emoji ?? "🎯")
                    .font(.system(size: 22))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "#F2711C").opacity(0.16))
                    .clipShape(Circle())
                Text(goal.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.dashNavy)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 78)
                Text("\(goal.pointsCost) pts")
                    .font(.system(size: 11))
                    .foregroundColor(.dashSubtle)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .dashboardCard(radius: 16, fill: Color(hex: "#F2711C").opacity(0.07), border: Color(hex: "#F2711C").opacity(0.25))
        }
        .buttonStyle(.plain)
    }
}
