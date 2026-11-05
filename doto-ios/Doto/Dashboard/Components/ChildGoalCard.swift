import SwiftUI

struct ChildGoalCard: View {
    let goal: ActiveGoal

    private var accent: Color {
        switch goal.status {
        case "approved":         return .dashGreen
        case "pending_approval": return Color(hex: "#E8A317")
        default:                 return .dashBlue
        }
    }

    private var pointsToGo: Int {
        goal.pointsCost - (goal.pointsCost * goal.progressPct / 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DashboardSectionHeader(title: "My goal")

            HStack(alignment: .top, spacing: 12) {
                Text(goal.emoji ?? "🎁")
                    .font(.system(size: 22))
                    .frame(width: 44, height: 44)
                    .background(accent.opacity(0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(goal.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.dashNavy)
                            .lineLimit(1)
                        Spacer(minLength: 6)
                        StatusBadge(status: goal.status)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(accent.opacity(0.18))
                            Capsule()
                                .fill(accent)
                                .frame(width: max(geo.size.width * CGFloat(min(100, goal.progressPct)) / 100,
                                                  goal.progressPct > 0 ? 8 : 0))
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(goal.progressPct)% of \(goal.pointsCost) pts")
                            .font(.system(size: 11))
                            .foregroundColor(.dashSubtle)
                        Spacer()
                        Text("\(pointsToGo) pts to go")
                            .font(.system(size: 11))
                            .foregroundColor(.dashSubtle)
                    }
                }
            }
            .padding(12)
            .dashboardCard(radius: 16, fill: accent.opacity(0.08), border: accent.opacity(0.25))
        }
    }
}

struct StatusBadge: View {
    let status: String

    var body: some View {
        let config: (text: String, color: Color, bg: Color) = {
            switch status {
            case "approved":
                return ("Approved", .dashGreen, Color(hex: "#DDF5E8"))
            case "pending_approval":
                return ("Pending", Color(hex: "#B7791F"), Color(hex: "#FDF0C9"))
            default:
                return ("Active", .dashBlue, .dashBlueTint)
            }
        }()

        DashboardBadge(text: config.text, foreground: config.color, background: config.bg)
    }
}
