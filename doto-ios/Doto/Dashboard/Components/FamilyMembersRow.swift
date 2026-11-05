import SwiftUI

struct FamilyMembersRow: View {
    let members: [FamilyMemberRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DashboardSectionHeader(title: "Our family")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(members) { member in
                        FamilyMemberCard(member: member)
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 2)
            }
        }
    }
}

struct FamilyMemberCard: View {
    let member: FamilyMemberRow

    private var streakColor: Color {
        member.streakStatus == "active" || member.streakStatus == "grace" ? Color(hex: "#F2711C") : .dashSubtle
    }

    var body: some View {
        VStack(spacing: 6) {
            AvatarView(
                name: member.displayName,
                color: member.color,
                size: 44,
                isActive: member.isSelf
            )

            Text(member.isSelf ? "You" : member.displayName)
                .font(.system(size: 13, weight: member.isSelf ? .bold : .semibold))
                .foregroundColor(member.isSelf ? Color(hex: member.color) : .dashNavy)
                .lineLimit(1)

            Text(member.role == "parent" ? "Parent" : member.streakDisplay)
                .font(.system(size: 11, weight: member.role != "parent" && member.streakStatus != "none" ? .semibold : .regular))
                .foregroundColor(member.role == "parent" ? .dashSubtle : streakColor)
        }
        .frame(width: 84)
        .padding(.vertical, 12)
        .dashboardCard(radius: 16,
                       fill: member.isSelf ? Color(hex: member.color).opacity(0.08) : .white,
                       border: member.isSelf ? Color(hex: member.color).opacity(0.3) : .dashCardBorder)
    }
}
