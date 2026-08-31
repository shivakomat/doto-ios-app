import SwiftUI

struct VerifyCodeView: View {
    let email: String
    let onResetComplete: () -> Void

    @State private var code = ""
    @State private var isResending = false
    @State private var resendMessage: String?
    @State private var showNewPassword = false
    @FocusState private var codeFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.open.fill")
                .font(.system(size: 50))
                .foregroundColor(.memberBlue)
                .padding(.top, 40)

            Text("Check your email")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.textPrimary)

            Text("We sent a 6-digit code to\n**\(email)**")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Hidden text field + visible digit boxes
            ZStack {
                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($codeFieldFocused)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .onChange(of: code) { newValue in
                        // Only allow digits, max 6
                        let filtered = String(newValue.filter(\.isNumber).prefix(6))
                        if filtered != newValue { code = filtered }
                    }

                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { index in
                        let digit = index < code.count
                            ? String(code[code.index(code.startIndex, offsetBy: index)])
                            : ""
                        Text(digit)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.textPrimary)
                            .frame(width: 46, height: 56)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        index < code.count ? Color.memberBlue : Color(hex: "#D1D5DB"),
                                        lineWidth: index == code.count ? 2 : 1.5
                                    )
                            )
                            .cornerRadius(8)
                    }
                }
                .onTapGesture { codeFieldFocused = true }
            }
            .padding(.top, 20)

            if let msg = resendMessage {
                Text(msg)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#1D9E75"))
            }

            Spacer()

            Button {
                resendCode()
            } label: {
                HStack(spacing: 4) {
                    if isResending {
                        ProgressView().scaleEffect(0.7)
                    }
                    Text("Didn't get it? Resend code")
                        .font(.system(size: 14))
                        .foregroundColor(.memberBlue)
                }
            }
            .disabled(isResending)

            PrimaryButton(title: "Continue") {
                showNewPassword = true
            }
            .disabled(code.count != 6)
            .opacity(code.count == 6 ? 1.0 : 0.6)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { codeFieldFocused = true }
        .navigationDestination(isPresented: $showNewPassword) {
            NewPasswordView(email: email, code: code, onSuccess: onResetComplete)
        }
    }

    private func resendCode() {
        isResending = true
        resendMessage = nil

        Task {
            do {
                let _: ResetRequestResponse = try await APIClient.shared.post(
                    "/auth/request-reset",
                    body: ResetRequestDTO(email: email)
                )
            } catch {
                // Always show success to prevent enumeration
            }
            await MainActor.run {
                isResending = false
                resendMessage = "Code resent!"
                code = ""
            }
        }
    }
}
