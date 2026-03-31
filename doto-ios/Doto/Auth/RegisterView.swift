import SwiftUI

enum RegistrationPath {
    case createFamily
    case joinFamily(inviteCode: String, role: String)
}

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    let path: RegistrationPath

    @State private var displayName  = ""
    @State private var username     = ""
    @State private var password     = ""
    @State private var confirmPw    = ""
    @State private var showPassword = false
    @State private var usernameError: String?

    private var confirmMismatch: Bool {
        !confirmPw.isEmpty && confirmPw != password
    }

    private var canSubmit: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidUsername(username) &&
        password.count >= 8 &&
        !confirmMismatch &&
        !confirmPw.isEmpty &&
        !authVM.isLoading
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                if case .joinFamily(let code, let role) = path {
                    JoinConfirmationBanner(inviteCode: code, role: role)
                }

                AuthTextField(label: "Display name", text: $displayName)

                VStack(alignment: .leading, spacing: 4) {
                    AuthTextField(
                        label: "Username",
                        text: Binding(
                            get: { username },
                            set: {
                                username = $0.lowercased()
                                usernameError = isValidUsername($0.lowercased()) || $0.isEmpty
                                    ? nil
                                    : "Letters, numbers, underscores only. No spaces."
                            }
                        ),
                        autocapitalization: .never
                    )
                    if let err = usernameError {
                        Text(err)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#E24B4A"))
                    } else {
                        Text("Letters, numbers, underscores only.")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                }

                AuthSecureField(
                    label: "Password (min. 8 characters)",
                    text: $password,
                    showPassword: $showPassword
                )

                AuthSecureField(
                    label: "Confirm password",
                    text: $confirmPw,
                    showPassword: $showPassword,
                    error: confirmMismatch ? "Passwords don't match." : nil
                )

                if let err = authVM.errorMessage {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#E24B4A"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(
                    title: authVM.isLoading ? "Creating account..." : "Create my account →",
                    isLoading: authVM.isLoading
                ) {
                    Task { await submit() }
                }
                .disabled(!canSubmit)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("Create your account")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { authVM.errorMessage = nil }
    }

    private func submit() async {
        let (inviteCode, role): (String?, String) = {
            if case .joinFamily(let code, let r) = path { return (code, r) }
            return (nil, "parent")
        }()
        await authVM.register(
            username: username,
            password: password,
            displayName: displayName,
            role: role,
            inviteCode: inviteCode
        )
    }

    private func isValidUsername(_ value: String) -> Bool {
        let regex = "^[a-z0-9_]{3,50}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: value)
    }
}

struct JoinConfirmationBanner: View {
    let inviteCode: String
    let role: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "#1D9E75"))
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text("Joining with code \(inviteCode)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#1D9E75"))
                Text("Role: \(role == "parent" ? "Parent" : "Child / Teen")")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "#F0FDF4"))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#1D9E75"), lineWidth: 1))
        .cornerRadius(8)
    }
}
