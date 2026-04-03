import SwiftUI

struct FamilyMembersRow: View {
    let members: [FamilyMemberRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Our family")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(members) { member in
                        FamilyMemberCard(member: member)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

struct FamilyMemberCard: View {
    let member: FamilyMemberRow

    var body: some View {
        VStack(spacing: 4) {
            AvatarView(
                name: member.displayName,
                color: member.color,
                size: 38,
                isActive: member.isSelf
            )

            Text(member.isSelf ? "You" : member.displayName)
                .font(.system(size: 9, weight: member.isSelf ? .bold : .regular))
                .foregroundColor(member.isSelf ? Color(hex: member.color) : .textSecondary)
                .lineLimit(1)
                .frame(maxWidth: 48)

            // Line 2 — streak if active/grace, or "Parent" label
            if member.role == "parent" {
                Text("Parent")
                    .font(.system(size: 8))
                    .foregroundColor(.textMuted)
            } else {
                Text(member.streakDisplay)
                    .font(.system(size: 8, weight: member.streakStatus != "none" ? .semibold : .regular))
                    .foregroundColor(
                        member.streakStatus == "active" ? .memberAmber :
                        member.streakStatus == "grace"  ? .memberAmber :
                        .textMuted
                    )
            }
        }
        .frame(minWidth: 48)
    }
}
