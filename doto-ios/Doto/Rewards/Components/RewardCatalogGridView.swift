import SwiftUI

/// "Reward Catalog" section on the Rewards tab — 2-column grid of catalog
/// cards (category icon chip, title, point cost). Parents get a "+" to add
/// items and context-menu Edit/Delete; children tap a card to set it as a goal.
struct RewardCatalogGridView: View {
    let items: [RewardCatalogItem]
    let isParent: Bool
    let memberBalance: Int
    var onAdd: (() -> Void)? = nil
    let onTapItem: (RewardCatalogItem) -> Void
    var onDeleteItem: ((RewardCatalogItem) -> Void)? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Reward Catalog")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
                if isParent, let onAdd {
                    Button("+ Add") { onAdd() }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.memberBlue)
                }
            }

            if items.isEmpty {
                Text(isParent ? "No rewards yet — tap + to add one." : "No rewards yet")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(items) { item in
                        catalogCard(item)
                    }
                }
            }
        }
    }

    private func catalogCard(_ item: RewardCatalogItem) -> some View {
        let category = item.rewardCategory
        return Button {
            onTapItem(item)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: category.resolvedIcon)
                    .font(.system(size: 20))
                    .foregroundColor(category.color)
                    .frame(width: 44, height: 44)
                    .background(category.color.opacity(0.12))
                    .clipShape(Circle())

                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(item.pointsCost) pts")
                    .font(.system(size: 11))
                    .foregroundColor(memberBalance >= item.pointsCost ? .memberGreen : .textMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
            .cornerRadius(10)
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
