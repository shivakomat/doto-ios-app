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
        AuthScreen(
            title: "Check your email",
            subtitle: "We sent a 6-digit code to \(email)",
            systemImage: "envelope.open.fill",
            centered: true,
            footer: {
                AnyView(
                    VStack(spacing: 12) {
                        Button {
                            resendCode()
                        } label: {
                            HStack(spacing: 4) {
                                if isResending {
                                    ProgressView().scaleEffect(0.7)
                                }
                                Text("Didn't get it? Resend code")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.dashBlue)
                            }
                        }
                        .disabled(isResending)

                        PrimaryButton(title: "Continue") {
                            showNewPassword = true
                        }
                        .disabled(code.count != 6)
                    }
                )
            }
        ) {
            VStack(spacing: 14) {
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

                    HStack(spacing: 8) {
                        ForEach(0..<6, id: \.self) { index in
                            let digit = index < code.count
                                ? String(code[code.index(code.startIndex, offsetBy: index)])
                                : ""
                            let active = index == code.count && codeFieldFocused
                            Text(digit)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.dashNavy)
                                .frame(maxWidth: 50)
                                .frame(height: 58)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            index < code.count || active ? Color.dashBlue : Color.dashCardBorder,
                                            lineWidth: active ? 2 : 1.5
                                        )
                                )
                                .shadow(color: Color.dashNavy.opacity(0.04), radius: 6, x: 0, y: 2)
                        }
                    }
                    .onTapGesture { codeFieldFocused = true }
                }
                .padding(.top, 8)

                if let msg = resendMessage {
                    AuthMessage(text: msg, kind: .success)
                }
            }
        }
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
