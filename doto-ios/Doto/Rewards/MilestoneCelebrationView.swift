import SwiftUI

struct MilestoneCelebrationView: View {
    let milestoneValue: String
    let onDismiss: () -> Void

    private var milestone: Milestone? { Milestone.from(milestoneValue) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appNavy, Color.memberBlue],
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
                        .foregroundColor(.appNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 28)
        }
    }
}
