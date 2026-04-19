import SwiftUI

struct VerifyCodeView: View {
    let email: String
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var codeVerified = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter verification code")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.top, 40)

                Text("Enter the 6-digit code we sent to\n\(email)")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // 6-digit code input
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        CodeDigitBox(
                            index: index,
                            code: $code,
                            onComplete: { verifyCode() }
                        )
                    }
                }
                .padding(.top, 30)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#E24B4A"))
                        .padding(.top, 16)
                }

                Spacer()

                Button {
                    resendCode()
                } label: {
                    Text("Didn't receive it? Resend")
                        .font(.system(size: 14))
                        .foregroundColor(.memberBlue)
                }
                .padding(.bottom, 20)

                Button {
                    verifyCode()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(code.count == 6 ? Color.memberBlue : Color.gray.opacity(0.3))
                .cornerRadius(12)
                .disabled(code.count != 6 || isLoading)
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

    private func verifyCode() {
        guard code.count == 6 else { return }

        isLoading = true
        errorMessage = nil

        // This will trigger navigation to NewPasswordView
        // For now, just simulate success
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                isLoading = false
                codeVerified = true
            }
        }
    }

    private func resendCode() {
        code = ""
        errorMessage = nil

        Task {
            do {
                let _: ResetRequestResponse = try await APIClient.shared.post(
                    "/api/auth/request-reset",
                    body: ResetRequestDTO(email: email)
                )
            } catch {
                // Always show success
            }
        }
    }
}

struct CodeDigitBox: View {
    let index: Int
    @Binding var code: String
    let onComplete: () -> Void

    private var digit: String {
        if index < code.count {
            let idx = code.index(code.startIndex, offsetBy: index)
            return String(code[idx])
        }
        return ""
    }

    var body: some View {
        Text(digit)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.textPrimary)
            .frame(width: 44, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(index < code.count ? Color.memberBlue : Color(hex: "#E2E8F0"), lineWidth: 2)
                    )
            )
    }
}
