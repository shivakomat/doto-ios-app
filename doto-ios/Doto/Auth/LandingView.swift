import SwiftUI

struct LandingView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 6) {
                    Text("Doto")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("Family life. Done.")
                        .font(.system(size: 16).italic())
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink(destination: RegisterView(path: .createFamily)) {
                        Text("Create a family")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    NavigationLink(destination: FamilyCodeEntryView()) {
                        Text("Join a family")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(.textMuted)
                        NavigationLink(destination: SignInView()) {
                            Text("Sign in →")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.memberBlue)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
            .background(Color.white.ignoresSafeArea())
        }
    }
}
