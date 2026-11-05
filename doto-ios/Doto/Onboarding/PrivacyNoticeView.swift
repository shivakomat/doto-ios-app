import SwiftUI

struct PrivacyNoticeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showTerms = false

    var body: some View {
        AuthScreen(
            title: "Welcome to Doto",
            subtitle: "Before you get started, here is how we protect your family's privacy.",
            systemImage: "lock.shield.fill",
            footer: {
                AnyView(
                    VStack(spacing: 12) {
                        VStack(spacing: 2) {
                            Text("By continuing you agree to our")
                                .font(.system(size: 13))
                                .foregroundColor(.dashSubtle)
                            HStack(spacing: 4) {
                                Button("Terms") {
                                    showTerms = true
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.dashBlue)
                                Text("and")
                                    .font(.system(size: 13))
                                    .foregroundColor(.dashSubtle)
                                Button("Privacy Policy") {
                                    if let url = LegalURLs.privacyPolicy {
                                        openURL(url)
                                    }
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.dashBlue)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        PrimaryButton(title: "Continue") {
                            UserDefaults.standard.set(true, forKey: "doto.privacyNoticeShown")
                            dismiss()
                        }
                    }
                )
            }
        ) {
            AuthCard {
                VStack(alignment: .leading, spacing: 14) {
                    DashboardBullet(text: "Children's accounts do not require an email address.")
                    DashboardBullet(text: "We do not collect location, photos, or advertising identifiers from children.")
                    DashboardBullet(text: "Parents control family membership and can remove children at any time.")
                    DashboardBullet(text: "We do not sell personal information or show behaviorally-targeted ads.")
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
    }
}
