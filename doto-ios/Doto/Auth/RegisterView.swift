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
    @State private var email        = ""
    @State private var password     = ""
    @State private var confirmPw    = ""
    @State private var showPassword = false
    @State private var usernameError: String?
    @State private var emailError: String?
    @State private var ageConfirmed = false

    @Environment(\.openURL) private var openURL

    private var isParent: Bool {
        if case .joinFamily(_, let role) = path {
            return role == "parent"
        }
        return true // createFamily defaults to parent
    }

    private var confirmMismatch: Bool {
        !confirmPw.isEmpty && confirmPw != password
    }

    private var canSubmit: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidUsername(username) &&
        password.count >= 8 &&
        !confirmMismatch &&
        !confirmPw.isEmpty &&
        (!isParent || isValidEmail(email)) &&
        ageConfirmed &&
        !authVM.isLoading
    }

    private var disabledReason: String? {
        if authVM.isLoading { return nil }
        if displayName.trimmingCharacters(in: .whitespaces).isEmpty { return "Enter a display name" }
        if !isValidUsername(username) { return "Username must be 3-50 characters, letters, numbers, underscores only" }
        if isParent && !isValidEmail(email) { return "Enter a valid email address" }
        if password.count < 8 { return "Password must be at least 8 characters" }
        if confirmMismatch { return "Passwords don't match" }
        if confirmPw.isEmpty { return "Confirm your password" }
        if !ageConfirmed { return "Confirm your age and consent to continue" }
        return nil
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
                                usernameError = nil // Clear API error on edit
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

                // Email field - only for parents
                if isParent {
                    VStack(alignment: .leading, spacing: 4) {
                        AuthTextField(
                            label: "Email",
                            text: Binding(
                                get: { email },
                                set: {
                                    email = $0.lowercased()
                                    emailError = nil
                                }
                            ),
                            autocapitalization: .never,
                            keyboardType: .emailAddress
                        )
                        if let err = emailError {
                            Text(err)
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#E24B4A"))
                        } else {
                            Text("Used for password recovery")
                                .font(.system(size: 11))
                                .foregroundColor(.textMuted)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    AuthSecureField(
                        label: "Password (min. 8 characters)",
                        text: $password,
                        showPassword: $showPassword
                    )
                    HStack {
                        Text("\(password.count) characters")
                            .font(.system(size: 11))
                            .foregroundColor(password.count >= 8 ? Color(hex: "#1D9E75") : Color(hex: "#D97706"))
                        Spacer()
                        if password.count >= 8 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#1D9E75"))
                                .font(.system(size: 11))
                        }
                    }
                }

                AuthSecureField(
                    label: "Confirm password",
                    text: $confirmPw,
                    showPassword: $showPassword,
                    error: confirmMismatch ? "Passwords don't match." : nil
                )

                if let err = authVM.errorMessage, usernameError == nil && emailError == nil {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#E24B4A"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let reason = disabledReason, !authVM.isLoading {
                    Text(reason)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#D97706"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $ageConfirmed) {
                        Text(isParent
                             ? "I am 13 years of age or older and I agree to the Terms and Privacy Policy."
                             : "I am 13 years of age or older, or I have permission from a parent or legal guardian who has agreed to the Terms and Privacy Policy.")
                            .font(.system(size: 13))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .toggleStyle(iOSCheckboxToggleStyle())

                    Button("View Privacy Policy") {
                        if let url = LegalURLs.privacyPolicy {
                            openURL(url)
                        }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.memberBlue)
                }
                .padding(.top, 4)

                PrimaryButton(
                    title: authVM.isLoading ? "Creating account..." : "Create my account →",
                    isLoading: authVM.isLoading
                ) {
                    Task { await submit() }
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1.0 : 0.6)
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
            inviteCode: inviteCode,
            email: isParent ? email : nil
        )
        // Check for specific errors to show inline
        if let err = authVM.errorMessage {
            if err.lowercased().contains("username") && err.lowercased().contains("taken") {
                usernameError = "This username is already taken. Try a different one."
            } else if err.lowercased().contains("email") {
                emailError = err
            }
        }
    }

    private func isValidUsername(_ value: String) -> Bool {
        let regex = "^[a-z0-9_]{3,50}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: value)
    }

    private func isValidEmail(_ value: String) -> Bool {
        let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: value)
    }
}

private struct iOSCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(configuration.isOn ? .memberBlue : .textMuted)
                configuration.label
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
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
