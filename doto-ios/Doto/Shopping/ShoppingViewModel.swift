import Foundation

@MainActor
class ShoppingViewModel: ObservableObject {
    @Published var lists: [ShoppingList] = []
    @Published var items: [ShoppingItem] = []
    @Published var selectedListId: String? = nil
    @Published var isLoading = false
    @Published var isLoadingItems = false
    @Published var errorMessage: String?

    var selectedList: ShoppingList? { lists.first { $0.id == selectedListId } }
    var checkedCount: Int { items.filter { $0.isChecked }.count }

    var groupedItems: [(category: ShoppingCategory, items: [ShoppingItem])] {
        let grouped = Dictionary(grouping: items) {
            ShoppingCategory(rawValue: $0.category) ?? .other
        }
        return ShoppingCategory.allCases
            .compactMap { cat in
                guard let catItems = grouped[cat], !catItems.isEmpty else { return nil }
                return (category: cat, items: catItems)
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

    func loadItems() async {
        guard let listId = selectedListId else { return }
        isLoadingItems = true; defer { isLoadingItems = false }
        do {
            items = try await APIClient.shared.get("/shopping/lists/\(listId)/items")
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

    func createList(name: String) async {
        struct CreateListRequest: Encodable { let name: String }
        do {
            let newList: ShoppingList = try await APIClient.shared.post(
                "/shopping/lists",
                body: CreateListRequest(name: name)
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
