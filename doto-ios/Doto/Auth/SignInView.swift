import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AuthTextField(label: "Username", text: $username, autocapitalization: .never)

            AuthSecureField(label: "Password", text: $password, showPassword: $showPassword)

            if let err = authVM.errorMessage {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#E24B4A"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(
                title: authVM.isLoading ? "Signing in..." : "Sign in",
                isLoading: authVM.isLoading
            ) {
                Task { await authVM.login(username: username, password: password) }
            }
            .disabled(username.isEmpty || password.isEmpty || authVM.isLoading)
            .padding(.top, 4)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { authVM.errorMessage = nil }
    }
}
