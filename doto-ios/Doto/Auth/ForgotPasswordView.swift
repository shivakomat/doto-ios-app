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
            AuthScreen(
                title: "Reset your password",
                subtitle: "Enter the email address associated with your account and we'll send you a 6-digit code.",
                systemImage: "lock.rotation",
                centered: true,
                footer: {
                    AnyView(
                        PrimaryButton(
                            title: isLoading ? "Sending..." : "Send reset code",
                            isLoading: isLoading
                        ) {
                            requestReset()
                        }
                        .disabled(email.isEmpty || isLoading)
                    )
                }
            ) {
                VStack(spacing: 14) {
                    AuthTextField(
                        label: "Email",
                        text: $email,
                        autocapitalization: .never,
                        keyboardType: .emailAddress
                    )

                    if let error = errorMessage {
                        AuthMessage(text: error)
                    }
                }
            }
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
        .tint(.dashBlue)
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
