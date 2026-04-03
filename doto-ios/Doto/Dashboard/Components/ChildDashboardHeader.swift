import SwiftUI

struct ChildDashboardHeader: View {
    let profile: DashboardProfile?
    let onAvatarTap: () -> Void

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = profile?.displayName ?? ""
        let emoji = hour < 12 ? "☀️" : hour < 17 ? "🌤" : "🌙"
        if hour < 12 { return "Good morning, \(name) \(emoji)" }
        if hour < 17 { return "Good afternoon, \(name) \(emoji)" }
        return "Good evening, \(name) \(emoji)"
    }

    var body: some View {
        ZStack {
            Color.appNavy
                .ignoresSafeArea(edges: .top)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(Date().dashboardDateLabel)
                        .font(.system(size: 10))
                        .foregroundColor(.appNavySub)
                }
                Spacer()
                // Avatar button for settings
                Button(action: onAvatarTap) {
                    AvatarView(
                        name: profile?.displayName ?? "",
                        color: profile?.color ?? "#185FA5",
                        size: 32
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(height: 70)
    }
}
