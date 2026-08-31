import SwiftUI

struct PasswordResetSuccessView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "#D1FAE5"))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(Color(hex: "#1D9E75"))
            }

            Text("Password reset!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)

            Text("Your password has been successfully reset.\nYou can now sign in with your new password.")
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            PrimaryButton(title: "Return to sign in") {
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.white.ignoresSafeArea())
    }
}
