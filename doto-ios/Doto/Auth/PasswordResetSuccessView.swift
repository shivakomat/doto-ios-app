import SwiftUI

struct PasswordResetSuccessView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Success icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "#D1FAE5"))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(Color(hex: "#1D9E75"))
                }
                .padding(.top, 60)

                Text("Password reset!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("Your password has been successfully reset. You can now log in with your new password.")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Return to login")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.memberBlue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
}

struct PasswordResetSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordResetSuccessView()
    }
}
