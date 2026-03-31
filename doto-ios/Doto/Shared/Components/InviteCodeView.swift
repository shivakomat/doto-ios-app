import SwiftUI

struct InviteCodeView: View {
    let code: String
    let familyName: String

    private var shareText: String {
        "Join \(familyName) on Doto! Enter this code in the app: \(code)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Family invite code")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)

            HStack {
                Text(code)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.memberBlue)
                    .tracking(6)

                Spacer()

                Button {
                    UIPasteboard.general.string = code
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(.memberBlue)
                }
            }
            .padding(14)
            .background(Color(hex: "#EFF6FF"))
            .cornerRadius(10)

            ShareLink(item: shareText) {
                Label("Share via iMessage / WhatsApp", systemImage: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundColor(.memberBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.memberBlue, lineWidth: 1)
                    )
                    .cornerRadius(8)
            }
        }
    }
}
