import SwiftUI

struct OverdueAlertBanner: View {
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            Text("🔴").font(.system(size: 14))
            Text("\(count) overdue task\(count == 1 ? "" : "s") need\(count == 1 ? "s" : "") attention")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.overdueText)
            Spacer()
            // Navigate to Tasks tab with overdue filter
            Text("View →")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#E24B4A"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.overdueBg)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#FECACA"), lineWidth: 1))
        .cornerRadius(8)
    }
}
