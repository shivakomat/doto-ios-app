import SwiftUI

struct PrivacyNoticeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showTerms = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to Doto")
                    .font(.system(size: 28, weight: .bold))
                Text("Before you get started, here is how we protect your family's privacy.")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                BulletLabel(text: "Children's accounts do not require an email address.")
                BulletLabel(text: "We do not collect location, photos, or advertising identifiers from children.")
                BulletLabel(text: "Parents control family membership and can remove children at any time.")
                BulletLabel(text: "We do not sell personal information or show behaviorally-targeted ads.")
            }

            Spacer()

            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("By continuing you agree to our")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                    Button("Terms") {
                        showTerms = true
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.memberBlue)
                    Text("and")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                    Button("Privacy Policy") {
                        if let url = LegalURLs.privacyPolicy {
                            openURL(url)
                        }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.memberBlue)
                    Spacer()
                }
                .multilineTextAlignment(.leading)

                Button {
                    UserDefaults.standard.set(true, forKey: "doto.privacyNoticeShown")
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.memberBlue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
    }
}

private struct BulletLabel: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.memberBlue)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 14))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}
