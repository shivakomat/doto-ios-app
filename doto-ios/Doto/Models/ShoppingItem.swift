import Foundation

struct ShoppingItem: Codable, Identifiable {
    let id: String
    let listId: String
    let familyId: String
    var name: String
    var quantity: String?
    var category: String
    var isChecked: Bool
    var checkedBy: String?
    var checkedAt: Date?
    let createdBy: String
    let createdAt: Date
    let updatedAt: Date
}

enum ShoppingCategory: String, CaseIterable {
    case produce   = "produce"
    case dairy     = "dairy"
    case meat      = "meat"
    case bakery    = "bakery"
    case household = "household"
    case frozen    = "frozen"
    case beverages = "beverages"
    case snacks    = "snacks"
    case other     = "other"

    var emoji: String {
        switch self {
        case .produce:   return "🥦"
        case .dairy:     return "🥛"
        case .meat:      return "🥩"
        case .bakery:    return "🧁"
        case .household: return "🧹"
        case .frozen:    return "❄️"
        case .beverages: return "🧃"
        case .snacks:    return "🍿"
        case .other:     return "📦"
        }
    }

    var displayName: String { rawValue.capitalized }

    static func detect(from name: String) -> ShoppingCategory {
        let n = name.lowercased()
        if ["apple","banana","spinach","lettuce","tomato","onion","carrot","broccoli"].contains(where: n.contains) { return .produce }
        if ["milk","cheese","yogurt","butter","cream","eggs"].contains(where: n.contains)                          { return .dairy   }
        if ["chicken","beef","pork","salmon","tuna","mince"].contains(where: n.contains)                          { return .meat    }
        if ["bread","rolls","bagels","croissant"].contains(where: n.contains)                                     { return .bakery  }
        if ["soap","bags","bleach","detergent","sponge","toilet"].contains(where: n.contains)                     { return .household }
        if ["frozen","ice cream","pizza"].contains(where: n.contains)                                             { return .frozen  }
        return .other
    }
}
