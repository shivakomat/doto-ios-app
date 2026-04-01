import SwiftUI

struct StreakRowView: View {
    let entry: LeaderboardEntry

    private var streakColor: Color {
        switch entry.streakStatus ?? "none" {
        case "active": return Color.memberAmber
        case "grace":  return Color.memberAmber
        default:       return Color.textMuted
        }
    }

    private var streakIcon: String {
        switch entry.streakStatus ?? "none" {
        case "active": return "🔥"
        case "grace":  return "🔸"
        default:       return "—"
        }
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
            AvatarView(name: entry.displayName, color: entry.color, size: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)
                if let status = entry.streakStatus {
                    Text(streakSubtitle(status))
                        .font(.system(size: 10))
                        .foregroundColor(status == "grace" ? Color.memberAmber : .textMuted)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Text(streakIcon).font(.system(size: 14))
                Text(streakValueLabel)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(streakColor)
            }
        }
        .padding(.vertical, 6)
    }
}
