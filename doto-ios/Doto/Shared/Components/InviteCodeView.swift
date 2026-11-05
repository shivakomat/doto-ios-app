import SwiftUI

struct InviteCodeView: View {
    let code: String
    let familyName: String

    private var shareText: String {
        "Join \(familyName) on Doto! Enter this code in the app: \(code)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Family invite code")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.dashNavy)

            HStack {
                Text(code)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.dashBlue)
                    .tracking(6)

                Spacer()

                Button {
                    UIPasteboard.general.string = code
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.dashBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(Color.dashBlueTint)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.dashBlueBorder, lineWidth: 1))

            ShareLink(item: shareText) {
                Label("Share via iMessage / WhatsApp", systemImage: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.dashBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.dashBlue, lineWidth: 1.2))
            }
        }
    }
}
