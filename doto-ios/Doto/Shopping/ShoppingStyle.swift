import SwiftUI

/// Icon + accent color for a shopping category card.
struct ShoppingGroupStyle {
    let symbol: String
    let color: Color

    private static let palette: [Color] = [
        Color(hex: "#F2711C"), Color(hex: "#2F7DF6"), Color(hex: "#1D9E75"),
        Color(hex: "#7A5AF8"), Color(hex: "#EC5C9A"), Color(hex: "#E8A317"),
        Color(hex: "#14A5B5")
    ]

    private static let symbols: [String: String] = [
        "clothing": "tshirt.fill", "tops": "tshirt.fill", "bottoms": "tshirt.fill",
        "shoes": "shoe.fill", "accessories": "eyeglasses",
        "toiletries": "drop.fill", "documents": "doc.text.fill", "tech": "bolt.fill",
        "medicine": "pills.fill", "vitamins": "leaf.fill", "first_aid": "cross.case.fill",
        "personal_care": "heart.fill", "gifts": "gift.fill", "decorations": "sparkles",
        "cake_treats": "birthday.cake.fill", "party_supplies": "party.popper.fill",
        "food_drinks": "fork.knife", "activities": "figure.play",
        "cleaning": "sparkles", "kitchen": "fork.knife", "bathroom": "drop.fill",
        "laundry": "washer.fill", "stationery": "pencil", "books": "book.fill",
        "movies_shows": "film.fill", "snacks": "popcorn.fill", "beverages": "cup.and.saucer.fill",
        "pet_food": "fork.knife", "toys": "teddybear.fill", "grooming": "scissors",
        "health": "cross.case.fill", "tools": "wrench.and.screwdriver.fill",
        "materials": "shippingbox.fill", "paint": "paintbrush.fill",
        "plumbing_electrical": "bolt.fill", "household": "house.fill",
        "general": "cart.fill", "other": "square.grid.2x2.fill"
    ]

    static func style(for key: String, listType: ShoppingListType, index: Int) -> ShoppingGroupStyle {
        let color = palette[index % palette.count]
        var symbol = "tag.fill"
        if listType == .groceries, let sub = GrocerySubcategory(rawValue: key) {
            symbol = sub.resolvedIcon
        } else if let s = symbols[key], UIImage(systemName: s) != nil {
            symbol = s
        }
        return ShoppingGroupStyle(symbol: symbol, color: color)
    }

    /// Stable accent for an item icon so the same symbol always gets the same color.
    static func itemColor(for symbol: String) -> Color {
        let hash = symbol.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7fffffff }
        return palette[hash % palette.count]
    }
}
