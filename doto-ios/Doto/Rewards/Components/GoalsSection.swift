import SwiftUI

/// "Family Goals" section: the active family goal (if any) followed by member and shared goals.
struct GoalsSection: View {
    var title: String = "Family Goals"
    var familyGoal: FamilyGoal? = nil
    let rewards: [Reward]
    let leaderboard: Leaderboard?
    let isParent: Bool
    let currentProfileId: String?
    let onRequest: (Reward) -> Void
    var onEdit: ((Reward) -> Void)? = nil
    var onDelete: ((Reward) -> Void)? = nil
    var limit: Int = 3

    @State private var showAll = false

    private enum Row: Identifiable {
        case family(FamilyGoal)
        case reward(Reward, balance: Int, isOwner: Bool, ownerName: String?)

        var id: String {
            switch self {
            case .family(let g):         return "family-\(g.id)"
            case .reward(let r, _, _, _): return "reward-\(r.id)"
            }
        }
    }

    private var rows: [Row] {
        var result: [Row] = []
        if let familyGoal { result.append(.family(familyGoal)) }
        let childEntries = leaderboard?.entries.filter { $0.role == "child" } ?? []
        for entry in childEntries {
            for reward in rewards where reward.memberId == entry.memberId {
                result.append(.reward(reward, balance: entry.totalPoints,
                                      isOwner: reward.memberId == currentProfileId,
                                      ownerName: entry.displayName))
            }
        }
        for reward in rewards where reward.memberId == nil {
            result.append(.reward(reward, balance: reward.currentProgress ?? 0, isOwner: false, ownerName: "Shared"))
        }
        return result
    }

    var body: some View {
        let all = rows
        let visible = showAll ? all : Array(all.prefix(limit))

        VStack(alignment: .leading, spacing: 10) {
            DashboardSectionHeader(
                title: title,
                actionTitle: all.count > limit ? (showAll ? "Show less" : "See all") : nil
            ) {
                withAnimation(.easeInOut(duration: 0.2)) { showAll.toggle() }
            }

            if all.isEmpty {
                Text("No goals yet")
                    .font(.system(size: 14))
                    .foregroundColor(.dashSubtle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .dashboardCard()
            } else {
                ForEach(Array(visible.enumerated()), id: \.element.id) { idx, row in
                    switch row {
                    case .family(let goal):
                        FamilyGoalCard(goal: goal, accentIndex: idx)
                    case .reward(let reward, let balance, let isOwner, let ownerName):
                        GoalCard(
                            reward: reward,
                            balance: balance,
                            accentIndex: idx,
                            ownerName: ownerName,
                            isOwner: isOwner,
                            isParent: isParent,
                            onRequest: { onRequest(reward) },
                            onEdit: onEdit != nil ? { onEdit?(reward) } : nil,
                            onDelete: onDelete != nil ? { onDelete?(reward) } : nil
                        )
                    }
                }
            }
        }
    }
}

struct GoalCard: View {
    let reward: Reward
    let balance: Int
    var accentIndex: Int = 0
    var ownerName: String? = nil
    let isOwner: Bool
    let isParent: Bool
    let onRequest: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?

    private var effectiveProgress: Int { reward.currentProgress ?? balance }
    private var progress: Double {
        min(1.0, Double(effectiveProgress) / Double(max(1, reward.pointsCost)))
    }
    private var toGo: Int { max(0, reward.pointsCost - effectiveProgress) }
    private var canClaim: Bool { balance >= reward.pointsCost && reward.status == "active" }
    private var isPending: Bool { reward.status == "pending_approval" }
    private var accent: Color { canClaim ? .dashGreen : DashboardPalette.accent(accentIndex) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let emoji = reward.emoji, !emoji.isEmpty {
                    Text(emoji).font(.system(size: 22))
                } else {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(accent)
                }
            }
            .frame(width: 40, height: 40)
            .background(accent.opacity(0.16))
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(reward.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.dashNavy)
                            .lineLimit(1)
                        if let ownerName {
                            Text(ownerName)
                                .font(.system(size: 11))
                                .foregroundColor(.dashSubtle)
                        }
                    }
                    Spacer(minLength: 6)
                    Text("\(reward.pointsCost) pts")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(accent)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(accent.opacity(0.18))
                        Capsule()
                            .fill(accent)
                            .frame(width: max(geo.size.width * progress, progress > 0 ? 8 : 0))
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(effectiveProgress) / \(reward.pointsCost) pts · \(toGo) to go")
                        .font(.system(size: 11))
                        .foregroundColor(.dashSubtle)
                    Spacer()

                    if isPending {
                        Text("Pending ⏳")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.conflictText)
                    } else if canClaim && isOwner {
                        Button(action: onRequest) {
                            Text("Claim! 🎉")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.dashGreen)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(10)
        .dashboardCard(radius: 16, fill: accent.opacity(0.08), border: accent.opacity(0.25))
        .contextMenu {
            if isParent {
                if let onEdit = onEdit {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit goal", systemImage: "pencil")
                    }
                }
                if let onDelete = onDelete {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete goal", systemImage: "trash")
                    }
                }
            }
        }
    }
}
