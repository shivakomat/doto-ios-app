import SwiftUI

struct PendingApprovalsSection: View {
    let rewards: [Reward]
    let leaderboard: Leaderboard?
    let onApprove: (Reward) -> Void
    let onDecline: (Reward) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashboardSectionHeader(title: "Pending approvals ⏳")

            ForEach(rewards) { reward in
                let entry = leaderboard?.entries.first { $0.memberId == reward.memberId }
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        if let e = entry {
                            AvatarView(name: e.displayName, color: e.color, size: 34)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reward.titleWithEmoji)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.dashNavy)
                            Text("\(entry?.displayName ?? "") · balance: \(entry?.totalPoints ?? 0) pts")
                                .font(.system(size: 12))
                                .foregroundColor(.dashSubtle)
                        }
                        Spacer()
                        Text("\(reward.pointsCost) pts")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.conflictText)
                    }

                    HStack(spacing: 8) {
                        Button { onApprove(reward) } label: {
                            Text("Approve ✓")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color.dashGreen)
                                .clipShape(Capsule())
                        }
                        Button { onDecline(reward) } label: {
                            Text("Decline")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.dashRedText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color.dashRedTint)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(12)
                .dashboardCard(radius: 16, fill: Color(hex: "#FEF6DC"), border: Color(hex: "#F6DF93"))
            }
        }
    }
}
