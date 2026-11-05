import SwiftUI

struct ChildWelcomeCard: View {
    let displayName: String

    var body: some View {
        VStack(spacing: 8) {
            Text("👋")
                .font(.system(size: 36))
            Text("Hi \(displayName)!")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.dashNavy)
            Text("You have no tasks or events today. Enjoy your free time!")
                .font(.system(size: 13))
                .foregroundColor(.dashSubtle)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .dashboardCard(radius: 16)
    }
}
