import SwiftUI

struct StreakRowView: View {
    let entry: LeaderboardEntry

    private var streakColor: Color {
        switch entry.streakStatus ?? "none" {
        case "active", "grace": return Color(hex: "#F2711C")
        default:                return Color.textMuted
        }
    }

    private var streakIcon: String {
        (entry.streakStatus ?? "none") == "active" ? "flame.fill" : "flame"
    }

    private var streakValueLabel: String {
        switch entry.streakStatus ?? "none" {
        case "active": return "\(entry.streak ?? 0) days"
        case "grace":  return "\(entry.streak ?? 0) grace"
        default:       return "0 days"
        }
    }

    private func streakSubtitle(_ status: String) -> String {
        switch status {
        case "active": return "All tasks done today ✓"
        case "grace":  return "Missed yesterday — 1 day to recover"
        default:       return "Streak ended — start again today"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: entry.displayName, color: entry.color, size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.dashNavy)
                if let status = entry.streakStatus {
                    Text(streakSubtitle(status))
                        .font(.system(size: 12))
                        .foregroundColor(status == "grace" ? Color.memberAmber : .dashSubtle)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: streakIcon)
                    .font(.system(size: 15))
                    .foregroundColor(streakColor)
                Text(streakValueLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(streakColor)
            }
        }
        .padding(.vertical, 6)
    }
}

/// Compact "Streaks" card for the This Week tab: one tile per member.
struct StreaksSummaryCard: View {
    let entries: [LeaderboardEntry]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("🔥").font(.system(size: 18))
                    Text("Streaks")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.dashNavy)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.dashRedText)
                }

                if entries.isEmpty {
                    Text("No streaks yet")
                        .font(.system(size: 13))
                        .foregroundColor(.dashSubtle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    HStack(spacing: 8) {
                        ForEach(Array(entries.prefix(3).enumerated()), id: \.element.id) { idx, entry in
                            tile(entry, accent: DashboardPalette.accent(idx))
                        }
                    }
                }
            }
            .padding(10)
            .dashboardCard(radius: 16, fill: Color(hex: "#FFF1EA"), border: Color(hex: "#F9D9C8"))
        }
        .buttonStyle(.plain)
    }

    private func tile(_ entry: LeaderboardEntry, accent: Color) -> some View {
        let active = (entry.streakStatus ?? "none") != "none"
        let color = active ? accent : Color.textMuted
        return VStack(spacing: 4) {
            Image(systemName: active ? "flame.fill" : "flame")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.16))
                .clipShape(Circle())
            Text("\(entry.streak ?? 0) days")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.dashNavy)
            Text(entry.displayName)
                .font(.system(size: 10))
                .foregroundColor(.dashSubtle)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Full streaks list for the Streaks tab.
struct StreaksListCard: View {
    let entries: [LeaderboardEntry]

    var body: some View {
        VStack(spacing: 0) {
            if entries.isEmpty {
                Text("No streaks yet")
                    .font(.system(size: 14))
                    .foregroundColor(.dashSubtle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            } else {
                ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                    StreakRowView(entry: entry)
                        .padding(.horizontal, 14)
                    if idx < entries.count - 1 {
                        Rectangle().fill(Color.dashCardBorder).frame(height: 1).padding(.horizontal, 14)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .dashboardCard()
    }
}
