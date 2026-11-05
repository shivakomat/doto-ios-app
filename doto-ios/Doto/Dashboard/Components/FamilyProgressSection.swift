import SwiftUI

struct FamilyProgressSection: View {
    let progress: [MemberProgress]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DashboardSectionHeader(title: "Family progress this week")

            VStack(spacing: 12) {
                ForEach(progress) { member in
                    MemberProgressRow(member: member)
                }
            }
            .padding(14)
            .dashboardCard()
        }
    }
}

struct MemberProgressRow: View {
    let member: MemberProgress

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            AvatarView(name: member.displayName, color: member.color, size: 34)

            VStack(spacing: 6) {
                HStack {
                    Text(member.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.dashNavy)
                    Spacer()
                    Text("\(member.tasksCompleted)/\(member.tasksTotal)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: member.color))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.dashTrack)
                        Capsule()
                            .fill(Color(hex: member.color))
                            .frame(width: max(geo.size.width * member.progressFraction,
                                              member.progressFraction > 0 ? 6 : 0))
                    }
                }
                .frame(height: 6)
            }
        }
    }
}
