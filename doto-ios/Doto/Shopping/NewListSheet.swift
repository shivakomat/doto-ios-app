import SwiftUI

/// New shopping list sheet — name plus a type picker that drives the list icon
/// and, for Groceries, aisle-style subcategory grouping.
struct NewListSheet: View {
    @ObservedObject var vm: ShoppingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var listType: ShoppingListType = .other
    @State private var isSubmitting = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            AuthScreen(
                title: "New list",
                subtitle: "Name it and pick a type — it sets the icon and how items are grouped.",
                footer: {
                    AnyView(
                        PrimaryButton(title: isSubmitting ? "Creating…" : "Create list", isLoading: isSubmitting) {
                            Task { await create() }
                        }
                        .disabled(!canCreate)
                    )
                }
            ) {
                VStack(alignment: .leading, spacing: 18) {
                    AuthTextField(label: "List name", text: $name, placeholder: "e.g. Weekly Groceries")

                    VStack(alignment: .leading, spacing: 10) {
                        Text("List type")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.dashNavy)

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(ShoppingListType.allCases, id: \.self) { type in
                                typeTile(type)
                            }
                        }
                    }

                    if listType == .groceries {
                        Text("Grocery items get grouped by store section automatically.")
                            .font(.system(size: 12))
                            .foregroundColor(.dashSubtle)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .tint(.dashBlue)
    }

    private func typeTile(_ type: ShoppingListType) -> some View {
        let selected = listType == type
        return Button {
            listType = type
        } label: {
            VStack(spacing: 6) {
                Image(systemName: type.resolvedIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(type.color)
                    .frame(width: 38, height: 38)
                    .background(type.color.opacity(0.14))
                    .clipShape(Circle())
                Text(type.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.dashNavy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .dashboardCard(radius: 14,
                           fill: selected ? type.color.opacity(0.1) : .white,
                           border: selected ? type.color : .dashCardBorder)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(type.color, lineWidth: selected ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
    }

    private func create() async {
        isSubmitting = true
        defer { isSubmitting = false }
        await vm.createList(
            name: name.trimmingCharacters(in: .whitespaces),
            listType: listType.rawValue
        )
        if vm.errorMessage == nil { dismiss() }
    }
}
