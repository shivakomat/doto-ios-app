import SwiftUI

struct ItemCreateRequest: Encodable {
    let name: String
    let quantity: String?
    let category: String
}

struct AddItemSheet: View {
    var listId: String?
    var onAdded: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var resolvedListId: String? = nil
    @State private var name = ""
    @State private var quantity = ""
    @State private var category: ShoppingCategory = .other
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusName: Bool

    var body: some View {
        NavigationView {
            Group {
                if isLoading && resolvedListId == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if resolvedListId == nil {
                    EmptyStateView(message: "No shopping list found.\nCreate one in the Shop tab first.", systemImage: "cart")
                } else {
                    Form {
                        Section {
                            TextField("Item name", text: $name)
                                .focused($focusName)
                                .onChange(of: name) { newValue in
                                    if !newValue.isEmpty {
                                        category = ShoppingCategory.detect(from: newValue)
                                    }
                                }
                            TextField("Quantity (optional)", text: $quantity)
                        }

                        Section(header: Text("Category")) {
                            Picker("Category", selection: $category) {
                                ForEach(ShoppingCategory.allCases, id: \.self) { cat in
                                    HStack {
                                        Text(cat.emoji)
                                        Text(cat.displayName)
                                    }.tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        if let err = errorMessage {
                            Section {
                                Text(err).foregroundColor(.red).font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                        } else if resolvedListId != nil {
                            Button("Add & Continue") { Task { await addItem(andContinue: true) } }
                                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                                .font(.system(size: 13))
                            Button("Add Item") { Task { await addItem(andContinue: false) } }
                                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                }
            }
            .onAppear {
                Task { await resolveListId() }
            }
        }
    }

    private func resolveListId() async {
        if let lid = listId {
            resolvedListId = lid
            focusName = true
            return
        }
        isLoading = true; defer { isLoading = false }
        if let lists: [ShoppingList] = try? await APIClient.shared.get("/shopping/lists"),
           let first = lists.first {
            resolvedListId = first.id
            focusName = true
        }
    }

    private func addItem(andContinue: Bool) async {
        guard let lid = resolvedListId else { return }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        let body = ItemCreateRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            quantity: quantity.isEmpty ? nil : quantity,
            category: category.rawValue
        )
        do {
            let _: ShoppingItem = try await APIClient.shared.post("/shopping/lists/\(lid)/items", body: body)
            onAdded?()
            if andContinue {
                name = ""; quantity = ""; category = .other
                focusName = true
            } else {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
