import SwiftUI

struct FamilyGoalCard: View {
    let goal: FamilyGoal

    private var totalContributed: Int {
        goal.contributions.reduce(0) { $0 + $1.weeklyPoints }
    }

    private var progress: Double {
        min(1.0, Double(goal.combinedWeeklyPoints) / Double(max(1, goal.pointsTarget)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(goal.emoji ?? "🎯") \(goal.title)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(goal.pointsTarget) pts")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.memberBlue.opacity(0.15))
                        .frame(height: 10)
                    contributionBar(totalWidth: geo.size.width)
                }
            }
            .frame(height: 10)

            HStack {
                Text("\(goal.combinedWeeklyPoints) / \(goal.pointsTarget) pts")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                Spacer()
                if goal.estimatedWeeks > 0 {
                    Text("~\(goal.estimatedWeeks) weeks")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
            }

            HStack(spacing: 8) {
                ForEach(goal.contributions, id: \.memberId) { c in
                    HStack(spacing: 4) {
                        AvatarView(name: c.displayName, color: c.color, size: 16)
                        Text("\(c.weeklyPoints)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(hex: "#EFF6FF"))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.memberBlue.opacity(0.3), lineWidth: 1))
        .cornerRadius(8)
    }

    private func contributionBar(totalWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            let target = max(1, goal.pointsTarget)
            ForEach(goal.contributions, id: \.memberId) { c in
                let fraction = Double(c.weeklyPoints) / Double(target)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: c.color))
                    .frame(width: totalWidth * min(1.0, fraction), height: 10)
            }
        }
    }
}
