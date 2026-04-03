import SwiftUI

struct ChildStatsCard: View {
    let profile: DashboardProfile
    let stats: ChildStats

    var body: some View {
        HStack(spacing: 0) {
            StatPill(
                value: "\(profile.pointsTotal)",
                label: "all-time pts",
                color: Color.memberAmber
            )
            Divider().frame(height: 40)
            StatPill(
                value: streakDisplay,
                label: streakLabel,
                color: streakColor
            )
            Divider().frame(height: 40)
            StatPill(
                value: "🥇 \(rankLabel(stats.weeklyRank))",
                label: "this week",
                color: Color.memberBlue
            )
        }
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
    }

    private var streakDisplay: String {
        switch profile.streakStatus {
        case "active": return "🔥 \(profile.streak ?? 0)"
        case "grace":  return "🔸 \(profile.streak ?? 0)"
        default:       return "—"
        }
    }

    private var streakLabel: String {
        switch profile.streakStatus {
        case "active": return "day streak"
        case "grace":  return "grace"
        default:       return "no streak"
        }
    }

    private var streakColor: Color {
        profile.streakStatus == nil || profile.streakStatus == "none" ? .textMuted : .memberAmber
    }

    private func rankLabel(_ rank: Int) -> String {
        switch rank {
        case 1: return "1st 🏆"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(rank)th"
        }
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}
