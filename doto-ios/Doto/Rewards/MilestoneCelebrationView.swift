import SwiftUI

struct MilestoneCelebrationView: View {
    let milestoneValue: String
    let onDismiss: () -> Void

    private var milestone: Milestone? { Milestone.from(milestoneValue) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.dashNavy, Color.dashBlue],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Text(milestone?.emoji ?? "🏅")
                    .font(.system(size: 72))

                VStack(spacing: 8) {
                    Text(milestone?.displayName ?? "Achievement!")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    Text("You've earned \(milestone?.threshold ?? 0) points all-time!")
                        .font(.system(size: 14))
                        .foregroundColor(.appNavySub)
                        .multilineTextAlignment(.center)
                }

                MilestoneProgressTrack(currentMilestone: milestoneValue)

                Spacer()

                Button(action: onDismiss) {
                    Text("Awesome! 🎉")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.dashNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 28)
        }
    }
}
