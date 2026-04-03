import SwiftUI

struct ChildGoalCard: View {
    let goal: ActiveGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(goal.emoji ?? "🎁")
                    .font(.system(size: 18))
                Text(goal.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
                StatusBadge(status: goal.status)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.cardBorder)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor)
                            .frame(width: geo.size.width * CGFloat(goal.progressPct) / 100, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(goal.progressPct)% of \(goal.pointsCost) pts")
                        .font(.system(size: 10))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("\(goal.pointsCost - (goal.pointsCost * goal.progressPct / 100)) pts to go")
                        .font(.system(size: 10))
                        .foregroundColor(.textMuted)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
    }

    private var progressColor: Color {
        switch goal.status {
        case "approved": return Color(hex: "#1D9E75")
        case "pending_approval": return Color.memberAmber
        default: return Color.memberBlue
        }
    }
}

struct StatusBadge: View {
    let status: String

    var body: some View {
        let config: (text: String, color: Color, bg: Color) = {
            switch status {
            case "approved":
                return ("Approved", Color(hex: "#1D9E75"), Color(hex: "#F0FDF4"))
            case "pending_approval":
                return ("Pending", Color.memberAmber, Color(hex: "#FEF3C7"))
            default:
                return ("Active", Color.memberBlue, Color(hex: "#EFF6FF"))
            }
        }()

        Text(config.text)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(config.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(config.bg)
            .cornerRadius(4)
    }
}
