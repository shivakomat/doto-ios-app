import SwiftUI

struct MilestoneProgressTrack: View {
    let currentMilestone: String

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(Milestone.all.enumerated()), id: \.offset) { index, m in
                let isEarned = isEarnedOrPast(m.value)
                let isCurrent = m.value == currentMilestone

                VStack(spacing: 4) {
                    Text(m.emoji).font(.system(size: isCurrent ? 26 : 18))
                        .opacity(isEarned ? 1.0 : 0.35)
                    Text("\(m.threshold)")
                        .font(.system(size: 8))
                        .foregroundColor(isEarned ? .white : Color.appNavySub.opacity(0.5))
                }

                if index < Milestone.all.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(isEarned ? 0.4 : 0.15))
                        .frame(width: 24, height: 1)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.12))
        .cornerRadius(12)
    }

    private func isEarnedOrPast(_ value: String) -> Bool {
        let order = ["bronze", "silver", "gold", "diamond"]
        guard let currentIdx = order.firstIndex(of: currentMilestone),
              let checkIdx = order.firstIndex(of: value) else { return false }
        return checkIdx <= currentIdx
    }
}
