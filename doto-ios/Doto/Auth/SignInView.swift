import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showForgotPassword = false

    var body: some View {
        AuthScreen(
            title: "Welcome back",
            subtitle: "Sign in to your family's Doto.",
            footer: {
                AnyView(
                    PrimaryButton(
                        title: authVM.isLoading ? "Signing in..." : "Sign in",
                        isLoading: authVM.isLoading
                    ) {
                        Task { await authVM.login(username: username, password: password) }
                    }
                    .disabled(username.isEmpty || password.isEmpty || authVM.isLoading)
                )
            }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                AuthTextField(label: "Username", text: $username, autocapitalization: .never)

                AuthSecureField(label: "Password", text: $password, showPassword: $showPassword)

                if let err = authVM.errorMessage {
                    AuthMessage(text: err)
                }

                HStack {
                    Spacer()
                    Button {
                        showForgotPassword = true
                    } label: {
                        Text("Forgot password?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.dashBlue)
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .onAppear { authVM.errorMessage = nil }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
}
