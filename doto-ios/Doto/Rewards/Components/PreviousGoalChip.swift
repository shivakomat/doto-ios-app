import SwiftUI

struct PreviousGoalChip: View {
    let goal: Reward
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(goal.emoji ?? "🎯").font(.system(size: 20))
                Text(goal.title)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(Color(hex: "#412402"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 60)
                Text("\(goal.pointsCost) pts")
                    .font(.system(size: 8))
                    .foregroundColor(Color(hex: "#633806"))
            }
            .padding(8)
            .background(Color(hex: "#FAEEDA"))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#FAC775")))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
