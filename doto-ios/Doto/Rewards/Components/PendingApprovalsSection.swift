import SwiftUI

struct PendingApprovalsSection: View {
    let rewards: [Reward]
    let leaderboard: Leaderboard?
    let onApprove: (Reward) -> Void
    let onDecline: (Reward) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pending approvals ⏳")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)

            ForEach(rewards) { reward in
                let entry = leaderboard?.entries.first { $0.memberId == reward.memberId }
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        if let e = entry {
                            AvatarView(name: e.displayName, color: e.color, size: 24)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reward.titleWithEmoji)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            HStack(spacing: 4) {
                                Text(entry?.displayName ?? "")
                                    .font(.system(size: 11))
                                    .foregroundColor(.textSecondary)
                                Text("·")
                                    .foregroundColor(.textMuted)
                                Text("balance: \(entry?.totalPoints ?? 0) pts")
                                    .font(.system(size: 11))
                                    .foregroundColor(.textMuted)
                            }
                        }
                        Spacer()
                        Text("\(reward.pointsCost) pts")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.conflictText)
                    }

                    HStack(spacing: 8) {
                        Button { onApprove(reward) } label: {
                            Text("Approve ✓")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.doneText)
                                .cornerRadius(6)
                        }
                        Button { onDecline(reward) } label: {
                            Text("Decline")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.overdueText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.overdueBg)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(12)
                .background(Color(hex: "#FEF3C7"))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#FCD34D"), lineWidth: 1))
                .cornerRadius(8)
            }
        }
    }
}
