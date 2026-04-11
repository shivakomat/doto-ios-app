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

    var storeTypeEmoji: String {
        let lowercased = name.lowercased()
        if lowercased.contains("costco") { return "🏢" }
        if lowercased.contains("target") { return "🎯" }
        if lowercased.contains("walmart") { return "🛍️" }
        if lowercased.contains("trader") || lowercased.contains("joe") { return "🌴" }
        if lowercased.contains("whole foods") || lowercased.contains("wholefoods") { return "🥬" }
        if lowercased.contains("safeway") { return "🛒" }
        if lowercased.contains("kroger") { return "🥖" }
        if lowercased.contains("amazon") { return "📦" }
        if lowercased.contains("aldi") { return "🛒" }
        if lowercased.contains("sprouts") { return "🌱" }
        if lowercased.contains("grocery") { return "🍎" }
        if lowercased.contains("pharmacy") || lowercased.contains("cvs") || lowercased.contains("walgreens") { return "💊" }
        if lowercased.contains("hardware") || lowercased.contains("home depot") || lowercased.contains("lowe") { return "🔨" }
        return "🛒" // default shopping cart
    }
}
