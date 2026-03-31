import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var mode: AuthMode = .signIn
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var usernameError: String? = nil
    @State private var confirmPasswordError: String? = nil

    private static let usernameRegex = /^[a-zA-Z0-9_]{6,12}$/

    private var usernameValid: Bool {
        (try? Self.usernameRegex.wholeMatch(in: username)) != nil
    }

    enum AuthMode { case signIn, signUp }

    private var isSignUp: Bool { mode == .signUp }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 48)

                VStack(spacing: 4) {
                    Text("Doto")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("Family life. Done.")
                        .font(.system(size: 15))
                        .italic()
                        .foregroundColor(.textSecondary)
                }

                Picker("Mode", selection: $mode) {
                    Text("Sign Up").tag(AuthMode.signUp)
                    Text("Sign In").tag(AuthMode.signIn)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: mode) { _ in
                    authVM.errorMessage = nil
                    usernameError = nil
                    confirmPasswordError = nil
                }

                VStack(spacing: 14) {
                    if isSignUp {
                        TextField("Display name", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onChange(of: username) { _ in validateUsername() }

                        if let err = usernameError {
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }

                    passwordField(
                        label: "Password",
                        text: $password,
                        show: $showPassword
                    )

                    if isSignUp {
                        passwordField(
                            label: "Confirm password",
                            text: $confirmPassword,
                            show: $showConfirmPassword
                        )
                        .onChange(of: confirmPassword) { _ in validateConfirmPassword() }

                        if let err = confirmPasswordError {
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)

                if let err = authVM.errorMessage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        if isSignUp && err.lowercased().contains("already") {
                            Button("Sign in instead?") { mode = .signIn }
                                .font(.system(size: 12))
                                .foregroundColor(.memberBlue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                Button {
                    validateUsername()
                    guard usernameError == nil else { return }
                    Task {
                        if isSignUp {
                            await authVM.register(
                                username: username,
                                password: password,
                                displayName: displayName,
                                role: "parent",
                                inviteCode: nil
                            )
                        } else {
                            await authVM.login(username: username, password: password)
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.memberBlue)
                            .frame(height: 48)
                        if authVM.isLoading {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white)
                                Text(isSignUp ? "Creating account..." : "Signing in...")
                                    .foregroundColor(.white)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                        } else {
                            Text(isSignUp ? "Create account" : "Sign in")
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                }
                .padding(.horizontal)
                .disabled(authVM.isLoading)

                Spacer()
            }
        }
        .background(Color.white.ignoresSafeArea())
    }

    @ViewBuilder
    private func passwordField(label: String, text: Binding<String>, show: Binding<Bool>) -> some View {
        HStack {
            Group {
                if show.wrappedValue {
                    TextField(label, text: text)
                } else {
                    SecureField(label, text: text)
                }
            }
            Button {
                show.wrappedValue.toggle()
            } label: {
                Image(systemName: show.wrappedValue ? "eye.slash" : "eye")
                    .foregroundColor(.textMuted)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "#D1D5DB"), lineWidth: 1)
        )
    }

    private func validateUsername() {
        guard !username.isEmpty else { usernameError = nil; return }
        if (try? Self.usernameRegex.wholeMatch(in: username)) == nil {
            usernameError = "6–12 characters, letters, numbers and _ only"
        } else {
            usernameError = nil
        }
    }

    private func validateConfirmPassword() {
        if !confirmPassword.isEmpty && confirmPassword != password {
            confirmPasswordError = "Passwords don't match"
        } else {
            confirmPasswordError = nil
        }
    }
}
