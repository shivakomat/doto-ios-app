import SwiftUI

struct ResetChildPasswordSheet: View {
    let memberId: String
    let memberName: String
    @Environment(\.dismiss) private var dismiss

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSuccess = false

    private var passwordValid: Bool {
        password.count >= 8
    }

    private var passwordsMatch: Bool {
        password == confirmPassword && !confirmPassword.isEmpty
    }

    private var canSubmit: Bool {
        passwordValid && passwordsMatch && !isLoading
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Reset password for \(memberName)")
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                }

                Section(header: Text("New Password")) {
                    HStack {
                        Group {
                            if showPassword {
                                TextField("New password", text: $password)
                            } else {
                                SecureField("New password", text: $password)
                            }
                        }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.textMuted)
                        }
                    }

                    HStack {
                        Text("\(password.count) characters")
                            .font(.system(size: 12))
                            .foregroundColor(passwordValid ? Color(hex: "#1D9E75") : Color(hex: "#D97706"))

                        Spacer()

                        if passwordValid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#1D9E75"))
                                .font(.system(size: 12))
                        }
                    }
                }

                Section(header: Text("Confirm Password")) {
                    HStack {
                        Group {
                            if showPassword {
                                TextField("Confirm password", text: $confirmPassword)
                            } else {
                                SecureField("Confirm password", text: $confirmPassword)
                            }
                        }

                        if !confirmPassword.isEmpty {
                            Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(passwordsMatch ? Color(hex: "#1D9E75") : Color(hex: "#E24B4A"))
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#E24B4A"))
                    }
                }

                if isSuccess {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#1D9E75"))
                            Text("Password reset successfully")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#1D9E75"))
                        }
                    }
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Reset") {
                            resetPassword()
                        }
                        .disabled(!canSubmit)
                    }
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
                let _: ChildResetResponse = try await APIClient.shared.post(
                    "/api/members/\(memberId)/reset-password",
                    body: ChildResetDTO(newPassword: password)
                )
                await MainActor.run {
                    isLoading = false
                    isSuccess = true
                    // Auto-dismiss after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch APIError.forbidden {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "You don't have permission to reset this password."
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to reset password. Please try again."
                }
            }
        }
    }
}

struct ChildResetDTO: Encodable {
    let newPassword: String
}

struct ChildResetResponse: Decodable {
    let reset: Bool
}
