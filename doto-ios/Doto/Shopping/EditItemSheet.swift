import SwiftUI

struct EditItemSheet: View {
    let item: ShoppingItem
    let listId: String
    @ObservedObject var vm: ShoppingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var quantity: String
    @State private var category: String
    @State private var categoryManuallyPicked = false
    @State private var selectedIcon: String?
    @State private var iconManuallyPicked = false
    @State private var showIconPicker = false
    @State private var isSubmitting = false

    private var listType: ShoppingListType {
        vm.lists.first { $0.id == listId }?.type ?? .other
    }

    init(item: ShoppingItem, listId: String, vm: ShoppingViewModel) {
        self.item = item
        self.listId = listId
        self.vm = vm
        _name = State(initialValue: item.name)
        _quantity = State(initialValue: item.quantity ?? "")
        _category = State(initialValue: item.category)
        _selectedIcon = State(initialValue: item.icon)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    HStack(spacing: 10) {
                        Button {
                            showIconPicker = true
                        } label: {
                            let symbol = selectedIcon
                                .map { ItemIconCatalog.resolve($0) }
                                ?? ItemIconCatalog.detect(from: name, for: listType)
                            Image(systemName: symbol)
                                .font(.system(size: 18))
                                .foregroundColor(listType.color)
                                .frame(width: 40, height: 40)
                                .background(listType.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        TextField("Item name", text: $name)
                            .autocorrectionDisabled()
                            .onChange(of: name) { newValue in
                                if !newValue.isEmpty {
                                    if !categoryManuallyPicked {
                                        category = ShoppingListCategory.detect(from: newValue, for: listType)
                                    }
                                    if !iconManuallyPicked {
                                        selectedIcon = ItemIconCatalog.detect(from: newValue, for: listType)
                                    }
                                }
                            }
                    }

                    TextField("Quantity (optional)", text: $quantity)

                    // Manual pick wins — typing stops auto-detecting once chosen.
                    Picker("Category", selection: Binding(
                        get: { category },
                        set: { category = $0; categoryManuallyPicked = true }
                    )) {
                        ForEach(ShoppingListCategory.options(for: listType), id: \.value) { option in
                            Text(option.label).tag(option.value)
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
            .sheet(isPresented: $showIconPicker) {
                TaskIconPickerView(
                    selected: Binding(
                        get: { selectedIcon },
                        set: { selectedIcon = $0; iconManuallyPicked = true }
                    ),
                    sections: ItemIconCatalog.sections(for: listType)
                )
            }

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
            let icon: String?
        }
        do {
            let _: ShoppingItem = try await APIClient.shared.put(
                "/shopping/lists/\(listId)/items/\(item.id)",
                body: EditBody(
                    name: name.trimmingCharacters(in: .whitespaces),
                    quantity: quantity.isEmpty ? nil : quantity,
                    category: category,
                    icon: selectedIcon
                )
            )
            await vm.loadItems()
            dismiss()
        } catch {
            // show inline error
        }
    }
}
