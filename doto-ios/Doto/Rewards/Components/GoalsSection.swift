import SwiftUI

struct GoalsSection: View {
    let rewards: [Reward]
    let leaderboard: Leaderboard?
    let isParent: Bool
    let currentProfileId: String?
    let onRequest: (Reward) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Goals")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)

            let childEntries = leaderboard?.entries.filter { $0.role == "child" } ?? []
            ForEach(childEntries) { entry in
                let memberRewards = rewards.filter { $0.memberId == entry.memberId }
                if !memberRewards.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            AvatarView(name: entry.displayName, color: entry.color, size: 20)
                            Text(entry.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        }

                        ForEach(memberRewards) { reward in
                            GoalCard(
                                reward: reward,
                                balance: entry.totalPoints,
                                memberColor: entry.color,
                                isOwner: reward.memberId == currentProfileId,
                                onRequest: { onRequest(reward) }
                            )
                        }
                    }
                }
            }
        }
    }
}

struct GoalCard: View {
    let reward: Reward
    let balance: Int
    let memberColor: String
    let isOwner: Bool
    let onRequest: () -> Void

    private var effectiveProgress: Int { reward.currentProgress ?? balance }
    private var progress: Double {
        min(1.0, Double(effectiveProgress) / Double(max(1, reward.pointsCost)))
    }
    private var toGo: Int { max(0, reward.pointsCost - effectiveProgress) }
    private var canClaim: Bool { balance >= reward.pointsCost && reward.status == "active" }
    private var isPending: Bool { reward.status == "pending_approval" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reward.titleWithEmoji)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(reward.pointsCost) pts")
                    .font(.system(size: 11))
                    .foregroundColor(.conflictText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#FAC775").opacity(0.4))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(canClaim ? Color.doneText : Color(hex: memberColor))
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(effectiveProgress) / \(reward.pointsCost) pts · \(toGo) to go")
                    .font(.system(size: 11))
                    .foregroundColor(.conflictText)
                Spacer()

                if isPending {
                    Text("Pending ⏳")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.conflictText)
                } else if canClaim && isOwner {
                    Button(action: onRequest) {
                        Text("Claim! 🎉")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.doneText)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(hex: "#FAEEDA"))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#FAC775"), lineWidth: 1))
        .cornerRadius(8)
    }
}
