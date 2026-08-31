import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isLoading = false
    @State private var showVerifyCode = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 50))
                    .foregroundColor(.memberBlue)
                    .padding(.top, 40)

                Text("Reset your password")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("Enter the email address associated with your account and we'll send you a 6-digit code.")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 4) {
                    AuthTextField(
                        label: "Email",
                        text: $email,
                        autocapitalization: .never,
                        keyboardType: .emailAddress
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#E24B4A"))
                        .padding(.horizontal, 24)
                }

                Spacer()

                PrimaryButton(
                    title: isLoading ? "Sending..." : "Send reset code",
                    isLoading: isLoading
                ) {
                    requestReset()
                }
                .disabled(email.isEmpty || isLoading)
                .opacity(email.isEmpty ? 0.6 : 1.0)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showVerifyCode) {
                VerifyCodeView(email: email, onResetComplete: {
                    showVerifyCode = false
                    showSuccess = true
                })
            }
            .fullScreenCover(isPresented: $showSuccess) {
                PasswordResetSuccessView()
            }
        }
    }

    private func requestReset() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let _: ResetRequestResponse = try await APIClient.shared.post(
                    "/auth/request-reset",
                    body: ResetRequestDTO(email: email)
                )
            } catch {
                // Silently continue — don't reveal if email exists
            }
            await MainActor.run {
                isLoading = false
                showVerifyCode = true
            }
        }
    }
}

struct ResetRequestDTO: Encodable {
    let email: String
}

struct ResetRequestResponse: Decodable {
    let sent: Bool
}
