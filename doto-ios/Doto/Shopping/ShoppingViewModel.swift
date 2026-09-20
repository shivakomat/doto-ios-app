import Foundation

@MainActor
class ShoppingViewModel: ObservableObject {
    @Published var lists: [ShoppingList] = []
    @Published var items: [ShoppingItem] = []
    @Published var selectedListId: String? = nil
    @Published var isLoading = false
    @Published var isLoadingItems = false
    @Published var errorMessage: String?
    @Published var editingItem: ShoppingItem? = nil

    var selectedList: ShoppingList? { lists.first { $0.id == selectedListId } }
    var checkedCount: Int { items.filter { $0.isChecked }.count }

    /// A display group — the item's category (aisles on groceries lists).
    /// Headers are text-only.
    struct ItemGroup: Identifiable {
        let title: String
        let items: [ShoppingItem]
        var id: String { title }
    }

    var groupedItems: [ItemGroup] {
        let listType = selectedList?.type ?? .other
        let grouped = Dictionary(grouping: items, by: { $0.category })
        // Follow the list type's category ordering; unknown values go last.
        let order = ShoppingListCategory.options(for: listType).map(\.value)
        let keys = grouped.keys.sorted { a, b in
            switch (order.firstIndex(of: a), order.firstIndex(of: b)) {
            case let (x?, y?): return x < y
            case (_?, nil):   return true
            case (nil, _?):   return false
            case (nil, nil):  return a < b
            }
        }
        return keys.map { key in
            ItemGroup(
                title: ShoppingListCategory.displayName(for: key, listType: listType),
                items: grouped[key] ?? []
            )
        }
    }

    func loadLists() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            lists = try await APIClient.shared.get("/shopping/lists")
            if selectedListId == nil, let first = lists.first {
                selectedListId = first.id
                await loadItems()
            }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadItems(for listId: String? = nil) async {
        let targetListId = listId ?? selectedListId
        guard let lid = targetListId else { return }
        isLoadingItems = true; defer { isLoadingItems = false }
        do {
            items = try await APIClient.shared.get("/shopping/lists/\(lid)/items")
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectList(_ id: String) async {
        selectedListId = id
        await loadItems()
    }

    func createList(name: String, listType: String = "other") async {
        struct CreateListRequest: Encodable { let name: String; let listType: String }
        do {
            let newList: ShoppingList = try await APIClient.shared.post(
                "/shopping/lists",
                body: CreateListRequest(name: name, listType: listType)
            )
            lists.append(newList)
            await selectList(newList.id)
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteList(_ id: String) async {
        do {
            try await APIClient.shared.delete("/shopping/lists/\(id)")
            lists.removeAll { $0.id == id }
            if selectedListId == id {
                selectedListId = lists.first?.id
                if selectedListId != nil { await loadItems() } else { items = [] }
            }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleItem(_ item: ShoppingItem) async {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        guard let listId = selectedListId else { return }
        items[idx].isChecked.toggle()
        do {
            struct CheckRequest: Encodable { let isChecked: Bool }
            let _: ShoppingItem = try await APIClient.shared.patch(
                "/shopping/lists/\(listId)/items/\(item.id)/check",
                body: CheckRequest(isChecked: items[idx].isChecked)
            )
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            items[idx].isChecked = item.isChecked
            errorMessage = error.localizedDescription
        }
    }

    /// Reassign an item's category (aisle on groceries lists) — manual override
    /// of auto-detection.
    func setCategory(_ item: ShoppingItem, _ category: String) async {
        guard let listId = selectedListId else { return }
        struct Body: Encodable { let category: String }
        do {
            let updated: ShoppingItem = try await APIClient.shared.put(
                "/shopping/lists/\(listId)/items/\(item.id)",
                body: Body(category: category)
            )
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = updated
            }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteItem(_ item: ShoppingItem) async {
        guard let listId = selectedListId else { return }
        do {
            try await APIClient.shared.delete("/shopping/lists/\(listId)/items/\(item.id)")
            items.removeAll { $0.id == item.id }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearChecked() async {
        guard let listId = selectedListId else { return }
        do {
            try await APIClient.shared.delete("/shopping/lists/\(listId)/items/checked")
            items.removeAll { $0.isChecked }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
