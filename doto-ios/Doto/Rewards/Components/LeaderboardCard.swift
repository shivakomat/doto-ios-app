import SwiftUI

struct LeaderboardCard: View {
    let leaderboard: Leaderboard
    let currentProfileId: String?
    var limit: Int = 3
    var onChildTap: ((LeaderboardEntry) -> Void)? = nil

    @State private var showAll = false

    private let medals = ["🥇", "🥈", "🥉"]

    private var visibleEntries: [LeaderboardEntry] {
        showAll ? leaderboard.entries : Array(leaderboard.entries.prefix(limit))
    }

    private var maxWeekly: Int { max(1, leaderboard.entries.map(\.weeklyPoints).max() ?? 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("This week's leaderboard 🏆")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.dashNavy)
                Spacer()
                if leaderboard.entries.count > limit {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showAll.toggle() }
                    } label: {
                        Text(showAll ? "Show less" : "See all")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.dashBlue)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(visibleEntries.enumerated()), id: \.element.id) { idx, entry in
                    Button {
                        if entry.role == "child" { onChildTap?(entry) }
                    } label: {
                        row(entry, idx: idx)
                    }
                    .buttonStyle(.plain)

                    if idx < visibleEntries.count - 1 {
                        Rectangle().fill(Color.dashCardBorder).frame(height: 1).padding(.horizontal, 12)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.dashCardBorder, lineWidth: 1))
        }
        .padding(10)
        .dashboardCard(radius: 16, fill: Color(hex: "#FFF1F1"), border: Color(hex: "#F9D5D5"))
    }

    private func row(_ entry: LeaderboardEntry, idx: Int) -> some View {
        let rank = leaderboard.entries.firstIndex(where: { $0.id == entry.id }) ?? idx
        return HStack(spacing: 10) {
            Text(rank < medals.count ? medals[rank] : "\(rank + 1)")
                .font(.system(size: rank < medals.count ? 18 : 13, weight: .semibold))
                .foregroundColor(.dashSubtle)
                .frame(width: 24)

            AvatarView(name: entry.displayName, color: entry.color, size: 30,
                       isActive: entry.memberId == currentProfileId)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text(entry.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.dashNavy)
                        .lineLimit(1)
                    if entry.memberId == currentProfileId {
                        Text("(you)")
                            .font(.system(size: 11))
                            .foregroundColor(.dashSubtle)
                    }
                    Spacer(minLength: 6)
                    Text("\(entry.weeklyPoints) pts")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.dashSubtle)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.dashTrack)
                        Capsule()
                            .fill(Color(hex: entry.color))
                            .frame(width: max(geo.size.width * CGFloat(entry.weeklyPoints) / CGFloat(maxWeekly),
                                              entry.weeklyPoints > 0 ? 6 : 0))
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
