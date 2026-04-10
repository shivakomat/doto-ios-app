import SwiftUI

struct ParentDashboardHeader: View {
    let profile: DashboardProfile?
    let members: [FamilyMemberSummary]
    let onAvatarTap: () -> Void
    let onMemberTap: (String) -> Void
    let onAddMember: () -> Void
    let selectedMemberId: String?

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = profile?.displayName ?? ""
        let emoji = hour < 12 ? "☀️" : hour < 17 ? "🌤" : "🌙"
        if hour < 12 { return "Good morning, \(name) \(emoji)" }
        if hour < 17 { return "Good afternoon, \(name) \(emoji)" }
        return "Good evening, \(name) \(emoji)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Greeting row
            ZStack {
                Color.appNavy
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text(Date().dashboardDateLabel)
                            .font(.system(size: 10))
                            .foregroundColor(.appNavySub)
                    }
                    Spacer()
                    Button(action: onAvatarTap) {
                        AvatarView(
                            name: profile?.displayName ?? "",
                            color: profile?.color ?? "#185FA5",
                            size: 28
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .frame(height: 70)

            // Avatar filter row
            if !members.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(members) { member in
                            AvatarView(
                                name: member.displayName,
                                color: member.color,
                                size: 26,
                                isActive: selectedMemberId == member.id
                            )
                            .onTapGesture {
                                onMemberTap(member.id)
                            }
                        }
                        // Invite "+" button
                        Button(action: onAddMember) {
                            Circle()
                                .fill(Color.cardBorder)
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Text("+")
                                        .font(.system(size: 14))
                                        .foregroundColor(.textMuted)
                                )
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .background(Color.appNavy)
            }
        }
        .background(Color.appNavy)
    }
}
