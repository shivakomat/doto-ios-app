import SwiftUI

struct PasswordResetSuccessView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AuthScreen(
            title: "Password reset!",
            subtitle: "Your password has been successfully reset. You can now sign in with your new password.",
            systemImage: "checkmark",
            iconColor: .dashGreen,
            centered: true,
            showLandscape: true,
            footer: {
                AnyView(
                    PrimaryButton(title: "Return to sign in") {
                        dismiss()
                    }
                    .padding(.bottom, 8)
                )
            }
        ) {
            EmptyView()
        }
    }
}
