import SwiftUI

/// Three stat tiles: all-time points, streak and weekly rank.
struct ChildStatsCard: View {
    let profile: DashboardProfile
    let stats: ChildStats

    var body: some View {
        HStack(spacing: 10) {
            StatPill(icon: "star.fill", value: "\(profile.pointsTotal)", label: "all-time pts", color: Color(hex: "#E8A317"))
            StatPill(icon: streakIcon, value: streakValue, label: streakLabel, color: streakColor)
            StatPill(icon: "trophy.fill", value: rankLabel(stats.weeklyRank), label: "this week", color: .dashBlue)
        }
    }

    private var streakIcon: String { profile.streakStatus == "active" ? "flame.fill" : "flame" }

    private var streakValue: String {
        switch profile.streakStatus {
        case "active", "grace": return "\(profile.streak ?? 0)"
        default:                return "—"
        }
    }

    private var streakLabel: String {
        switch profile.streakStatus {
        case "active": return "day streak"
        case "grace":  return "grace day"
        default:       return "no streak"
        }
    }

    private var streakColor: Color {
        profile.streakStatus == nil || profile.streakStatus == "none" ? .textMuted : Color(hex: "#F2711C")
    }

    private func rankLabel(_ rank: Int) -> String {
        switch rank {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(rank)th"
        }
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.16))
                .clipShape(Circle())
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.dashNavy)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.dashSubtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .dashboardCard(radius: 16)
    }
}
