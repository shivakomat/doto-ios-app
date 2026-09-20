import SwiftUI

struct ItemCreateRequest: Encodable {
    let name: String
    let quantity: String?
    let category: String
    let icon: String?
}

struct AddItemSheet: View {
    let availableLists: [ShoppingList]
    let preselectedListId: String?
    @ObservedObject var vm: ShoppingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedListId: String = ""
    @State private var name = ""
    @State private var quantity = ""
    @State private var category: String = "other"
    @State private var categoryManuallyPicked = false
    @State private var selectedIcon: String? = nil
    @State private var iconManuallyPicked = false
    @State private var showIconPicker = false
    @State private var isSubmitting = false
    @State private var isLoadingLists = false
    @State private var loadedLists: [ShoppingList] = []
    @State private var errorMessage: String?
    @FocusState private var focusName: Bool

    var effectiveLists: [ShoppingList] {
        availableLists.isEmpty ? loadedLists : availableLists
    }

    var selectedList: ShoppingList? {
        effectiveLists.first { $0.id == selectedListId }
    }

    var body: some View {
        NavigationStack {
            Form {
                // ── List picker — shown first ──────────────────────────
                Section("Add to") {
                    if isLoadingLists {
                        ProgressView("Loading lists...")
                            .frame(maxWidth: .infinity)
                    } else if effectiveLists.isEmpty {
                        Text("No lists yet — create a list first")
                            .font(.system(size: 13))
                            .foregroundColor(.textMuted)
                    } else {
                        Picker("List", selection: $selectedListId) {
                            ForEach(effectiveLists) { list in
                                HStack(spacing: 8) {
                                    Image(systemName: list.type.resolvedIcon)
                                        .foregroundColor(list.type.color)
                                    Text(list.name)
                                }
                                .tag(list.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                // ── Item details ───────────────────────────────────────
                Section("Item") {
                    HStack(spacing: 10) {
                        Button {
                            showIconPicker = true
                        } label: {
                            let type = selectedList?.type ?? .other
                            let symbol = selectedIcon
                                .map { ItemIconCatalog.resolve($0) }
                                ?? ItemIconCatalog.detect(from: name, for: type)
                            Image(systemName: symbol)
                                .font(.system(size: 18))
                                .foregroundColor(type.color)
                                .frame(width: 40, height: 40)
                                .background(type.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        TextField("Item name", text: $name)
                            .focused($focusName)
                            .onChange(of: name) { newValue in
                                if !newValue.isEmpty {
                                    let type = selectedList?.type ?? .other
                                    if !categoryManuallyPicked {
                                        category = ShoppingListCategory.detect(from: newValue, for: type)
                                    }
                                    if !iconManuallyPicked {
                                        selectedIcon = ItemIconCatalog.detect(from: newValue, for: type)
                                    }
                                }
                            }
                    }

                    TextField("Quantity (optional, e.g. × 2, 500g)", text: $quantity)
                        .font(.system(size: 14))

                    // Manual pick wins — typing stops auto-detecting once chosen.
                    Picker("Category", selection: Binding(
                        get: { category },
                        set: { category = $0; categoryManuallyPicked = true }
                    )) {
                        ForEach(ShoppingListCategory.options(for: selectedList?.type ?? .other),
                                id: \.value) { option in
                            Text(option.label).tag(option.value)
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
                    .foregroundColor(.textMuted)
            )

            // ── Buttons at the bottom ──────────────────────────────────
            VStack(spacing: 10) {
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#E24B4A"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                // Add & Continue — adds item, keeps sheet open
                Button {
                    Task { await submitItem(andContinue: true) }
                } label: {
                    Text(isSubmitting ? "Adding..." : "Add & Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                          || selectedListId.isEmpty
                          || isSubmitting)

                // Add Item — adds and dismisses
                Button {
                    Task { await submitItem(andContinue: false) }
                } label: {
                    Text(isSubmitting ? "Adding..." : "Add Item")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                          || selectedListId.isEmpty
                          || isSubmitting)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .onAppear {
            Task {
                // Load lists if not provided
                if availableLists.isEmpty {
                    isLoadingLists = true
                    if let lists: [ShoppingList] = try? await APIClient.shared.get("/shopping/lists") {
                        loadedLists = lists
                    }
                    isLoadingLists = false
                }
                // Pre-select the active list, fall back to first list
                selectedListId = preselectedListId ?? effectiveLists.first?.id ?? ""
                category = ShoppingListCategory.options(for: selectedList?.type ?? .other)
                    .contains { $0.value == category } ? category : "other"
                focusName = true
            }
        }
        .onChange(of: selectedListId) { _ in
            // Category sets and icon pools differ per list type — clear manual
            // picks and re-detect for the new type.
            let type = selectedList?.type ?? .other
            categoryManuallyPicked = false
            iconManuallyPicked = false
            category = ShoppingListCategory.detect(from: name, for: type)
            selectedIcon = ItemIconCatalog.detect(from: name, for: type)
        }
        .sheet(isPresented: $showIconPicker) {
            TaskIconPickerView(
                selected: Binding(
                    get: { selectedIcon },
                    set: { selectedIcon = $0; iconManuallyPicked = true }
                ),
                sections: ItemIconCatalog.sections(for: selectedList?.type ?? .other)
            )
        }
    }

    private func submitItem(andContinue: Bool) async {
        guard !selectedListId.isEmpty,
              !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let _: ShoppingItem = try await APIClient.shared.post(
                "/shopping/lists/\(selectedListId)/items",
                body: ItemCreateRequest(
                    name: name.trimmingCharacters(in: .whitespaces),
                    quantity: quantity.isEmpty ? nil : quantity,
                    category: category,
                    icon: selectedIcon
                )
            )

            if andContinue {
                // Clear name and quantity, keep sheet open
                name = ""
                quantity = ""
                category = "other"
                categoryManuallyPicked = false
                selectedIcon = nil
                iconManuallyPicked = false
                focusName = true
            } else {
                dismiss()
            }

            // Notify the shopping view to refresh
            await vm.loadItems(for: selectedListId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
