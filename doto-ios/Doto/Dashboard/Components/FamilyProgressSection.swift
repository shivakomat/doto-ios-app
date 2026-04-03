import SwiftUI

struct FamilyProgressSection: View {
    let progress: [MemberProgress]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Family this week")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textPrimary)

            VStack(spacing: 10) {
                ForEach(progress) { member in
                    MemberProgressRow(member: member)
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
        }
    }
}

struct MemberProgressRow: View {
    let member: MemberProgress

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                AvatarView(name: member.displayName, color: member.color, size: 20)
                Text(member.displayName)
                    .font(.system(size: 11))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(member.tasksCompleted)/\(member.tasksTotal)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: member.color))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.cardBorder)
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: member.color))
                        .frame(width: geo.size.width * member.progressFraction, height: 5)
                }
            }
            .frame(height: 5)
        }
    }
}
