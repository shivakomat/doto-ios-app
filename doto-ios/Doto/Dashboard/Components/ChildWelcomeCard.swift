import SwiftUI

struct ChildWelcomeCard: View {
    let displayName: String

    var body: some View {
        VStack(spacing: 8) {
            Text("👋")
                .font(.system(size: 32))
            Text("Hi \(displayName)!")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)
            Text("You have no tasks or events today. Enjoy your free time!")
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
    }
}
