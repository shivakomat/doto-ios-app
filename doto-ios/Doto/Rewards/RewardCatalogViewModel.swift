import Foundation

@MainActor
class RewardCatalogViewModel: ObservableObject {
    @Published var items: [RewardCatalogItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAddSheet = false
    @Published var editingItem: RewardCatalogItem?

    func load() async {
        isLoading = true; defer { isLoading = false }
        do {
            items = try await APIClient.shared.get("/rewards/catalog")
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addItem(emoji: String?, title: String, cost: Int) async {
        struct CreateCatalogRequest: Encodable {
            let title: String; let emoji: String?; let pointsCost: Int
        }
        do {
            let item: RewardCatalogItem = try await APIClient.shared.post(
                "/rewards/catalog",
                body: CreateCatalogRequest(title: title, emoji: emoji, pointsCost: cost)
            )
            items.append(item)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateItem(id: String, emoji: String?, title: String, cost: Int) async {
        struct UpdateCatalogRequest: Encodable {
            let title: String; let emoji: String?; let pointsCost: Int
        }
        do {
            let updated: RewardCatalogItem = try await APIClient.shared.put(
                "/rewards/catalog/\(id)",
                body: UpdateCatalogRequest(title: title, emoji: emoji, pointsCost: cost)
            )
            if let idx = items.firstIndex(where: { $0.id == id }) {
                items[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteItem(_ item: RewardCatalogItem) async {
        do {
            try await APIClient.shared.delete("/rewards/catalog/\(item.id)")
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
