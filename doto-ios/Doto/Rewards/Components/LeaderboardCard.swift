import SwiftUI

struct LeaderboardCard: View {
    let leaderboard: Leaderboard
    let currentProfileId: String?
    var onChildTap: ((LeaderboardEntry) -> Void)? = nil

    private let medals = ["🥇", "🥈", "🥉"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This week's leaderboard 🏆")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(leaderboard.entries.enumerated()), id: \.element.id) { idx, entry in
                    Button {
                        if entry.role == "child" { onChildTap?(entry) }
                    } label: {
                        HStack(spacing: 10) {
                            Text(idx < medals.count ? medals[idx] : "\(idx + 1)")
                                .font(.system(size: idx < medals.count ? 16 : 12))
                                .frame(width: 22)
                            AvatarView(
                                name: entry.displayName,
                                color: entry.color,
                                size: 22,
                                isActive: entry.memberId == currentProfileId
                            )
                            HStack(spacing: 4) {
                                Text(entry.displayName)
                                    .font(.system(size: 13))
                                    .foregroundColor(.textPrimary)
                                if entry.memberId == currentProfileId {
                                    Text("(you)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textMuted)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("\(entry.weeklyPoints) wk")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(idx == 0 ? .memberBlue : .textSecondary)
                                Text("\(entry.totalPoints) total")
                                    .font(.system(size: 10))
                                    .foregroundColor(.textMuted)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    if idx < leaderboard.entries.count - 1 {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder, lineWidth: 1))
            .cornerRadius(8)
        }
    }
}
