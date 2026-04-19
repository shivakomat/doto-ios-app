import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isLoading = false
    @State private var emailSent = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if emailSent {
                    // Success state - show check your email message
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.memberBlue)
                        .padding(.top, 40)

                    Text("Check your email")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.textPrimary)

                    Text("We've sent a 6-digit reset code to\n\(email)")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)

                    Spacer()

                    Button {
                        // Navigate to code verification
                    } label: {
                        Text("Enter code")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.memberBlue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Button {
                        resendCode()
                    } label: {
                        Text("Resend code")
                            .font(.system(size: 14))
                            .foregroundColor(.memberBlue)
                    }
                    .padding(.top, 8)

                    Spacer()
                } else {
                    // Initial state - email input
                    Text("Reset your password")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .padding(.top, 40)

                    Text("Enter your email address and we'll send you a code to reset your password.")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)

                        TextField("Enter your email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#E24B4A"))
                            .padding(.horizontal, 24)
                    }

                    Spacer()

                    Button {
                        requestReset()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send code")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(email.isEmpty ? Color.gray.opacity(0.3) : Color.memberBlue)
                    .cornerRadius(12)
                    .disabled(email.isEmpty || isLoading)
                    .padding(.horizontal)

                    Spacer()
                }
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

    private func requestReset() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let _: ResetRequestResponse = try await APIClient.shared.post(
                    "/api/auth/request-reset",
                    body: ResetRequestDTO(email: email)
                )
                await MainActor.run {
                    isLoading = false
                    emailSent = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Always show success to prevent email enumeration
                    emailSent = true
                }
            }
        }
    }

    private func resendCode() {
        requestReset()
    }
}

struct ResetRequestDTO: Encodable {
    let email: String
}

struct ResetRequestResponse: Decodable {
    let sent: Bool
}
