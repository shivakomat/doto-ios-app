import SwiftUI

struct CatalogItemRow: View {
    let item: RewardCatalogItem
    let memberBalance: Int
    let onTap: () -> Void

    private var canAfford: Bool { memberBalance >= item.pointsCost }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(item.emoji ?? "🎯").font(.system(size: 18))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textPrimary)
                    Text("\(item.pointsCost) pts")
                        .font(.system(size: 11))
                        .foregroundColor(canAfford ? Color(hex: "#1D9E75") : .textMuted)
                }
                Spacer()
                Text("Set goal →")
                    .font(.system(size: 12))
                    .foregroundColor(.memberBlue)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .background(Color.white)
    }
}
