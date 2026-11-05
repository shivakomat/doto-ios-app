import SwiftUI

struct FamilyGoalCard: View {
    let goal: FamilyGoal
    var accentIndex: Int = 0

    private var accent: Color { DashboardPalette.accent(accentIndex) }

    private var progress: Double {
        min(1.0, Double(goal.combinedWeeklyPoints) / Double(max(1, goal.pointsTarget)))
    }

    private var toGo: Int { max(0, goal.pointsTarget - goal.combinedWeeklyPoints) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let emoji = goal.emoji, !emoji.isEmpty {
                    Text(emoji).font(.system(size: 22))
                } else {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accent)
                }
            }
            .frame(width: 40, height: 40)
            .background(accent.opacity(0.16))
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(goal.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.dashNavy)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text("\(goal.pointsTarget) pts")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(accent)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(accent.opacity(0.18))
                        contributionBar(totalWidth: geo.size.width)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(goal.combinedWeeklyPoints) / \(goal.pointsTarget) pts · \(toGo) to go")
                        .font(.system(size: 11))
                        .foregroundColor(.dashSubtle)
                    Spacer()
                    if goal.estimatedWeeks > 0 {
                        Text("~\(goal.estimatedWeeks) weeks")
                            .font(.system(size: 11))
                            .foregroundColor(.dashSubtle)
                    }
                }

                if !goal.contributions.isEmpty {
                    HStack(spacing: 10) {
                        ForEach(goal.contributions, id: \.memberId) { c in
                            HStack(spacing: 4) {
                                AvatarView(name: c.displayName, color: c.color, size: 18)
                                Text("\(c.weeklyPoints)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.dashSubtle)
                            }
                        }
                    }
                }
            }
        }
        .padding(10)
        .dashboardCard(radius: 16, fill: accent.opacity(0.08), border: accent.opacity(0.25))
    }

    private func contributionBar(totalWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            let target = max(1, goal.pointsTarget)
            ForEach(goal.contributions, id: \.memberId) { c in
                let fraction = Double(c.weeklyPoints) / Double(target)
                Rectangle()
                    .fill(Color(hex: c.color))
                    .frame(width: totalWidth * min(1.0, fraction), height: 8)
            }
        }
        .clipShape(Capsule())
    }
}
