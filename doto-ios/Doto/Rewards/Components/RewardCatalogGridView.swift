import SwiftUI

/// "Reward Catalog" section — tiles with a category icon chip, title and point cost.
/// `.preview` shows a single row of four with "See all"; `.full` is the 2-column grid.
/// Parents get "+ Add" and context-menu Edit/Delete; children tap a tile to set it as a goal.
struct RewardCatalogGridView: View {
    enum Style { case preview, full }

    let items: [RewardCatalogItem]
    let isParent: Bool
    let memberBalance: Int
    var style: Style = .full
    var onAdd: (() -> Void)? = nil
    var onSeeAll: (() -> Void)? = nil
    let onTapItem: (RewardCatalogItem) -> Void
    var onDeleteItem: ((RewardCatalogItem) -> Void)? = nil

    private var visibleItems: [RewardCatalogItem] {
        style == .preview ? Array(items.prefix(4)) : items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch style {
            case .preview:
                DashboardSectionHeader(
                    title: "Reward Catalog",
                    actionTitle: items.count > 4 || onSeeAll != nil ? "See all" : nil,
                    action: onSeeAll
                )
            case .full:
                DashboardSectionHeader(
                    title: "Reward Catalog",
                    actionTitle: isParent && onAdd != nil ? "+ Add" : nil,
                    action: onAdd
                )
            }

            if items.isEmpty {
                Text(isParent ? "No rewards yet — tap + Add to create one." : "No rewards yet")
                    .font(.system(size: 14))
                    .foregroundColor(.dashSubtle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .dashboardCard()
            } else if style == .preview {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(visibleItems) { item in
                        catalogTile(item)
                    }
                    if visibleItems.count < 4 {
                        ForEach(0..<(4 - visibleItems.count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(visibleItems) { item in
                        catalogTile(item)
                    }
                }
            }
        }
    }

    private func catalogTile(_ item: RewardCatalogItem) -> some View {
        let category = item.rewardCategory
        let affordable = memberBalance >= item.pointsCost
        return Button {
            onTapItem(item)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: category.resolvedIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(category.color)
                    .frame(width: 34, height: 34)
                    .background(category.color.opacity(0.14))
                    .clipShape(Circle())

                Text(item.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.dashNavy)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, minHeight: 28)

                Text("\(item.pointsCost) pts")
                    .font(.system(size: 11))
                    .foregroundColor(affordable && !isParent ? .dashGreen : .dashSubtle)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .dashboardCard(radius: 14)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isParent {
                Button {
                    onTapItem(item)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                if let onDeleteItem {
                    Button(role: .destructive) {
                        onDeleteItem(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}
