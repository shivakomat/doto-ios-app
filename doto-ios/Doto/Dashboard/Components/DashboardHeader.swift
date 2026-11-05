import SwiftUI

/// Dashboard header shared by parent and child dashboards:
/// greeting + date on the left, profile avatar (opens Settings) on the right.
struct DashboardHeader: View {
    let profile: DashboardProfile?
    let onAvatarTap: () -> Void

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = profile?.displayName ?? ""
        let period = hour < 12 ? "morning" : hour < 17 ? "afternoon" : "evening"
        return "Good \(period), \(name)"
    }

    private var emoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 12 ? "☀️" : hour < 17 ? "🌤" : "🌙"
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                (Text(greeting) + Text(" \(emoji)").font(.system(size: 22)))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.dashNavy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(Date().dashboardDateLabel)
                    .font(.system(size: 14))
                    .foregroundColor(.dashSubtle)
            }
            Spacer(minLength: 12)
            Button(action: onAvatarTap) {
                AvatarView(
                    name: profile?.displayName ?? "",
                    color: profile?.color ?? "#1D9E75",
                    size: 38
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }
}
