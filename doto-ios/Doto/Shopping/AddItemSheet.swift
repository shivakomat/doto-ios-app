import SwiftUI

struct ItemCreateRequest: Encodable {
    let name: String
    let quantity: String?
    let category: String
}

struct AddItemSheet: View {
    let availableLists: [ShoppingList]
    let preselectedListId: String?
    @ObservedObject var vm: ShoppingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedListId: String = ""
    @State private var name = ""
    @State private var quantity = ""
    @State private var category: ShoppingCategory = .other
    @State private var isSubmitting = false
    @State private var isLoadingLists = false
    @State private var loadedLists: [ShoppingList] = []
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
                                    Text(list.storeTypeEmoji)
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
                    TextField("Item name", text: $name)
                        .focused($focusName)
                        .onChange(of: name) { newValue in
                            if !newValue.isEmpty {
                                category = ShoppingCategory.detect(from: newValue)
                            }
                        }

                    TextField("Quantity (optional, e.g. × 2, 500g)", text: $quantity)
                        .font(.system(size: 14))

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
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
                    .foregroundColor(.textMuted)
            )

            // ── Buttons at the bottom ──────────────────────────────────
            VStack(spacing: 10) {
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
                focusName = true
            }
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
                    category: category.rawValue
                )
            )

            if andContinue {
                // Clear name and quantity, keep sheet open
                name = ""
                quantity = ""
                category = .other
                focusName = true
            } else {
                dismiss()
            }

            // Notify the shopping view to refresh
            await vm.loadItems(for: selectedListId)
        } catch {
            // Show error — keep sheet open
        }
    }
}
