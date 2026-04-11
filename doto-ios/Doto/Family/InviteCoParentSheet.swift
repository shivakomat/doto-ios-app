import SwiftUI

struct InviteCoParentSheet: View {
    let inviteCode: String
    let familyName: String
    @Environment(\.dismiss) private var dismiss

    private var shareText: String {
        "Join our family on Doto! Download the app and enter code: \(inviteCode)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.cardBorder)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            // Title
            Text("Invite a co-parent")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            // Instructions blurb
            Text("Share this code with your partner. They'll open the Doto app, tap \"Join a family\" on the welcome screen, and enter the code below.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .lineSpacing(3)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 16)

            // Invite code display
            VStack(alignment: .leading, spacing: 6) {
                Text("Family invite code")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)

                HStack {
                    Text(inviteCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.memberBlue)
                        .tracking(6)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = inviteCode
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.memberBlue)
                    }
                }
            }
            .padding(16)
            .background(Color.selectedDayBg)
            .cornerRadius(12)
            .padding(.horizontal, 20)

            // How it works — short 3-step blurb
            VStack(alignment: .leading, spacing: 10) {
                Text("How it works")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textSecondary)

                HowItWorksStep(number: "1", text: "They download Doto and open the app")
                HowItWorksStep(number: "2", text: "Tap \"Join a family\" on the welcome screen")
                HowItWorksStep(number: "3", text: "Enter the code above and create their account")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()

            // Share button
            ShareLink(item: shareText) {
                Label("Share invite via iMessage / WhatsApp",
                      systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .presentationDetents([.large])
    }
}

struct HowItWorksStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.selectedDayBg)
                    .frame(width: 22, height: 22)
                Text(number)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.memberBlue)
            }
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
