import SwiftUI

struct EditItemSheet: View {
    let item: ShoppingItem
    let listId: String
    @ObservedObject var vm: ShoppingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var quantity: String
    @State private var category: ShoppingCategory
    @State private var isSubmitting = false

    init(item: ShoppingItem, listId: String, vm: ShoppingViewModel) {
        self.item = item
        self.listId = listId
        self.vm = vm
        _name = State(initialValue: item.name)
        _quantity = State(initialValue: item.quantity ?? "")
        _category = State(initialValue: ShoppingCategory(rawValue: item.category) ?? .other)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Item name", text: $name)
                        .autocorrectionDisabled()

                    TextField("Quantity (optional)", text: $quantity)

                    Picker("Category", selection: $category) {
                        ForEach(ShoppingCategory.allCases, id: \.self) { cat in
                            HStack {
                                Text(cat.emoji)
                                Text(cat.displayName)
                            }
                            .tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
                    .foregroundColor(.textMuted)
            )

            // Buttons at the bottom
            VStack(spacing: 10) {
                Button {
                    Task { await saveEdit() }
                } label: {
                    Text(isSubmitting ? "Saving..." : "Save Changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func saveEdit() async {
        isSubmitting = true; defer { isSubmitting = false }
        struct EditBody: Encodable {
            let name: String; let quantity: String?; let category: String
        }
        do {
            let _: ShoppingItem = try await APIClient.shared.put(
                "/shopping/lists/\(listId)/items/\(item.id)",
                body: EditBody(
                    name: name.trimmingCharacters(in: .whitespaces),
                    quantity: quantity.isEmpty ? nil : quantity,
                    category: category.rawValue
                )
            )
            await vm.loadItems()
            dismiss()
        } catch {
            // show inline error
        }
    }
}
