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
        AuthScreen(
            title: "Create new password",
            subtitle: "Must be at least 8 characters.",
            systemImage: "lock.shield.fill",
            centered: true,
            footer: {
                AnyView(
                    PrimaryButton(
                        title: isLoading ? "Resetting..." : "Reset password",
                        isLoading: isLoading
                    ) {
                        resetPassword()
                    }
                    .disabled(!canSubmit)
                )
            }
        ) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    AuthSecureField(
                        label: "New password",
                        text: $password,
                        showPassword: $showPassword
                    )
                    HStack {
                        Text("\(password.count) characters")
                            .font(.system(size: 12))
                            .foregroundColor(passwordValid ? .dashGreen : Color(hex: "#B7791F"))
                        Spacer()
                        if passwordValid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.dashGreen)
                                .font(.system(size: 12))
                        }
                    }
                }

                AuthSecureField(
                    label: "Confirm password",
                    text: $confirmPassword,
                    showPassword: $showPassword,
                    error: !confirmPassword.isEmpty && !passwordsMatch ? "Passwords don't match" : nil
                )

                if let error = errorMessage {
                    AuthMessage(text: error)
                }
            }
        }
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
