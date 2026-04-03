import SwiftUI

struct PendingApprovalNudge: View {
    let approval: PendingApproval
    let onApprove: () -> Void
    let onDeny: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Member avatar
            AvatarView(name: approval.memberName, color: approval.memberColor, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(approval.emoji ?? "🎁")
                        .font(.system(size: 14))
                    Text(approval.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }

                Text("\(approval.memberName) · \(approval.pointsCost) pts · Balance: \(approval.memberBalance)")
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onDeny) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textMuted)
                        .frame(width: 28, height: 28)
                        .background(Color.white)
                        .cornerRadius(6)
                }

                Button(action: onApprove) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.memberBlue)
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color(hex: "#FEF3C7"))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#FDE68A"), lineWidth: 1))
        .cornerRadius(8)
    }
}
