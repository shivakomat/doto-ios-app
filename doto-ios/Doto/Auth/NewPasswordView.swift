import SwiftUI

struct NewPasswordView: View {
    let email: String
    let code: String
    let onSuccess: () -> Void

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var passwordValid: Bool { password.count >= 8 }
    private var passwordsMatch: Bool { password == confirmPassword && !confirmPassword.isEmpty }
    private var canSubmit: Bool { passwordValid && passwordsMatch && !isLoading }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(.memberBlue)
                .padding(.top, 40)

            Text("Create new password")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.textPrimary)

            Text("Must be at least 8 characters.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)

            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    AuthSecureField(
                        label: "New password",
                        text: $password,
                        showPassword: $showPassword
                    )
                    HStack {
                        Text("\(password.count) characters")
                            .font(.system(size: 11))
                            .foregroundColor(passwordValid ? Color(hex: "#1D9E75") : Color(hex: "#D97706"))
                        Spacer()
                        if passwordValid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#1D9E75"))
                                .font(.system(size: 11))
                        }
                    }
                }

                AuthSecureField(
                    label: "Confirm password",
                    text: $confirmPassword,
                    showPassword: $showPassword,
                    error: !confirmPassword.isEmpty && !passwordsMatch ? "Passwords don't match" : nil
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
                title: isLoading ? "Resetting..." : "Reset password",
                isLoading: isLoading
            ) {
                resetPassword()
            }
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1.0 : 0.6)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func resetPassword() {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let _: ResetPasswordResponse = try await APIClient.shared.post(
                    "/auth/reset-password",
                    body: ResetPasswordDTO(code: code, newPassword: password)
                )
                await MainActor.run {
                    isLoading = false
                    onSuccess()
                }
            } catch APIError.validation(let msg) {
                await MainActor.run {
                    isLoading = false
                    errorMessage = msg
                }
            } catch APIError.notFound {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid or expired code. Please request a new one."
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct ResetPasswordDTO: Encodable {
    let code: String
    let newPassword: String
}

struct ResetPasswordResponse: Decodable {
    let reset: Bool
}
