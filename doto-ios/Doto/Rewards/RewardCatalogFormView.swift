import SwiftUI

/// Create/edit form for a reward catalog item. Replaces `AddCatalogItemSheet`:
/// the free-text emoji field is replaced by an icon button paired with the
/// title field that opens `RewardCategoryPickerSheet`.
struct RewardCatalogFormView: View {
    let editingItem: RewardCatalogItem?
    let onSave: (RewardCategory, String, Int, String?) -> Void

    @State private var title = ""
    @State private var category: RewardCategory? = nil
    @State private var cost = 50
    @State private var itemDescription = ""
    @State private var showCategoryPicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 12) {
                            iconButton
                            TextField("Reward title", text: $title)
                        }
                        Text(category == nil ? "Tap to add an icon" : "Tap icon to change")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                }

                Section(header: Text("Points cost")) {
                    Stepper("\(cost) pts", value: $cost, in: 5...500, step: 5)
                }

                Section(header: Text("Description (optional)")) {
                    TextField("Optional", text: $itemDescription, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle(editingItem == nil ? "Add reward" : "Edit reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            category ?? .custom,
                            title,
                            cost,
                            itemDescription.isEmpty ? nil : itemDescription
                        )
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                RewardCategoryPickerSheet(selected: Binding(
                    get: { category ?? .custom },
                    set: { category = $0 }
                ))
            }
            .onAppear {
                if let item = editingItem {
                    title = item.title
                    category = item.category.flatMap { RewardCategory(rawValue: $0) } ?? .custom
                    cost = item.pointsCost
                    itemDescription = item.description ?? ""
                }
            }
        }
    }

    @ViewBuilder
    private var iconButton: some View {
        Button {
            showCategoryPicker = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                if let category {
                    Image(systemName: category.resolvedIcon)
                        .font(.system(size: 24))
                        .foregroundColor(category.color)
                        .frame(width: 52, height: 52)
                        .background(category.color.opacity(0.12))
                        .cornerRadius(12)
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(category.color)
                        .background(Circle().fill(Color.white).padding(2))
                        .offset(x: 4, y: 4)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.textMuted)
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.cardBorder, style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }
}
