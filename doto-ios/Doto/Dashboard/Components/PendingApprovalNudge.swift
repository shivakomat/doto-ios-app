import SwiftUI

struct PendingApprovalNudge: View {
    let approval: PendingApproval
    let onApprove: () -> Void
    let onDeny: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: approval.memberName, color: approval.memberColor, size: 38)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(approval.emoji ?? "🎁")
                        .font(.system(size: 14))
                    Text(approval.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.dashNavy)
                        .lineLimit(1)
                }

                Text("\(approval.memberName) · \(approval.pointsCost) pts · Balance: \(approval.memberBalance)")
                    .font(.system(size: 12))
                    .foregroundColor(.dashSubtle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 6)

            HStack(spacing: 8) {
                Button(action: onDeny) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.dashRedText)
                        .frame(width: 34, height: 34)
                        .background(Color.dashRedTint)
                        .clipShape(Circle())
                }

                Button(action: onApprove) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.dashGreen)
                        .clipShape(Circle())
                }
            }
        }
        .padding(12)
        .dashboardCard(radius: 16, fill: Color(hex: "#FEF6DC"), border: Color(hex: "#F6DF93"))
    }
}
