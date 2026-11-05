import SwiftUI

struct InviteCoParentSheet: View {
    let inviteCode: String
    let familyName: String
    @Environment(\.dismiss) private var dismiss

    private var shareText: String {
        "Join our family on Doto! Download the app and enter code: \(inviteCode)"
    }

    var body: some View {
        ZStack {
            DashboardBackground(showLandscape: false)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Capsule()
                        .fill(Color.dashCardBorder)
                        .frame(width: 36, height: 4)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)

                    Text("Invite a co-parent")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.dashNavy)

                    Text("Share this code with your partner. They'll open the Doto app, tap \"Join a family\" on the welcome screen, and enter the code below.")
                        .font(.system(size: 15))
                        .foregroundColor(.dashSubtle)
                        .lineSpacing(3)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Family invite code")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.dashNavy)

                        HStack {
                            Text(inviteCode)
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(.dashBlue)
                                .tracking(6)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = inviteCode
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.dashBlue)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(16)
                    .dashboardCard(radius: 16, fill: .dashBlueTint, border: .dashBlueBorder)

                    VStack(alignment: .leading, spacing: 12) {
                        DashboardSectionHeader(title: "How it works")
                        AuthCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HowItWorksStep(number: "1", text: "They download Doto and open the app")
                                HowItWorksStep(number: "2", text: "Tap \"Join a family\" on the welcome screen")
                                HowItWorksStep(number: "3", text: "Enter the code above and create their account")
                            }
                        }
                    }

                    ShareLink(item: shareText) {
                        Label("Share invite via iMessage / WhatsApp",
                              systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 6)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
            }
        }
        .presentationDetents([.large])
    }
}

struct HowItWorksStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.dashBlue)
                .frame(width: 28, height: 28)
                .background(Color.dashBlueTint)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.dashNavy)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
