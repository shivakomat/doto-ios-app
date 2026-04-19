import SwiftUI

struct NewPasswordView: View {
    let email: String
    let code: String
    @Environment(\.dismiss) private var dismiss
    @State private var onSuccess: () -> Void

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var passwordValid: Bool {
        password.count >= 8
    }

    private var passwordsMatch: Bool {
        password == confirmPassword && !confirmPassword.isEmpty
    }

    private var canSubmit: Bool {
        passwordValid && passwordsMatch && !isLoading
    }

    init(email: String, code: String, onSuccess: @escaping () -> Void = {}) {
        self.email = email
        self.code = code
        self._onSuccess = State(initialValue: onSuccess)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create new password")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.top, 40)

                Text("Your new password must be at least 8 characters long.")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("New password")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)

                    HStack {
                        Group {
                            if showPassword {
                                TextField("Enter new password", text: $password)
                            } else {
                                SecureField("Enter new password", text: $password)
                            }
                        }
                        .textFieldStyle(.roundedBorder)

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.textMuted)
                        }
                    }

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
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Confirm password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm password")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)

                    HStack {
                        Group {
                            if showPassword {
                                TextField("Confirm new password", text: $confirmPassword)
                            } else {
                                SecureField("Confirm new password", text: $confirmPassword)
                            }
                        }
                        .textFieldStyle(.roundedBorder)

                        if !confirmPassword.isEmpty {
                            Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(passwordsMatch ? Color(hex: "#1D9E75") : Color(hex: "#E24B4A"))
                        }
                    }
                }
                .padding(.horizontal, 24)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#E24B4A"))
                        .padding(.horizontal, 24)
                }

                Spacer()

                Button {
                    resetPassword()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Reset password")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSubmit ? Color.memberBlue : Color.gray.opacity(0.3))
                .cornerRadius(12)
                .disabled(!canSubmit)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.bottom, 32)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
                    "/api/auth/reset-password",
                    body: ResetPasswordDTO(code: code, newPassword: password)
                )
                await MainActor.run {
                    isLoading = false
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid or expired code. Please try again."
                    // Clear code for security
                    password = ""
                    confirmPassword = ""
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
