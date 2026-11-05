import SwiftUI

struct CatalogItemRow: View {
    let item: RewardCatalogItem
    let memberBalance: Int
    let onTap: () -> Void

    private var canAfford: Bool { memberBalance >= item.pointsCost }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                let category = item.rewardCategory
                Image(systemName: category.resolvedIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(category.color)
                    .frame(width: 36, height: 36)
                    .background(category.color.opacity(0.14))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.dashNavy)
                    Text("\(item.pointsCost) pts")
                        .font(.system(size: 12))
                        .foregroundColor(canAfford ? .dashGreen : .dashSubtle)
                }
                Spacer()
                Text("Set goal →")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.dashBlue)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
