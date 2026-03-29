import Foundation

struct ShoppingList: Codable, Identifiable {
    let id: String
    let familyId: String
    var name: String
    let itemCount: Int
    let checkedCount: Int
    let createdBy: String
    let createdAt: Date
    let updatedAt: Date
}
