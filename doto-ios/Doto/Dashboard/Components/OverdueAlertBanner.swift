import SwiftUI

struct OverdueAlertBanner: View {
    let count: Int
    var onViewTapped: (() -> Void)? = nil

    var body: some View {
        Button {
            onViewTapped?()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.dashRed)
                    .clipShape(Circle())
                Text("\(count) overdue task\(count == 1 ? "" : "s") need\(count == 1 ? "s" : "") attention")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.dashRedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 8)
                Text("View →")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.dashRedText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .dashboardCard(radius: 12, fill: .dashRedTint, border: .dashRedBorder)
        }
        .buttonStyle(.plain)
    }
}
