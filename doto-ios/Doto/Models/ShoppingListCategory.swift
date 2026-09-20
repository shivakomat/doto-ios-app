import Foundation

/// Per-list-type category sets. Categories are text-only groupings — for
/// groceries lists they are the store aisles; other types get their own set.
enum ShoppingListCategory {

    /// Ordered (value, label) pairs for a list type — drives the picker and grouping.
    static func options(for type: ShoppingListType) -> [(value: String, label: String)] {
        switch type {
        case .groceries:
            return GrocerySubcategory.allCases.map { ($0.rawValue, $0.displayName) }
        case .birthday:
            return [("gifts", "Gifts"), ("cake_treats", "Cake & Treats"),
                    ("decorations", "Decorations"), ("party_supplies", "Party Supplies"),
                    ("food_drinks", "Food & Drinks"), ("activities", "Activities"),
                    ("other", "Other")]
        case .holiday:
            return [("decorations", "Decorations"), ("gifts", "Gifts"),
                    ("food_drinks", "Food & Drinks"), ("clothing", "Clothing"),
                    ("other", "Other")]
        case .movies:
            return [("movies_shows", "Movies & Shows"), ("snacks", "Snacks"),
                    ("beverages", "Beverages"), ("other", "Other")]
        case .household:
            return [("cleaning", "Cleaning"), ("kitchen", "Kitchen"),
                    ("bathroom", "Bathroom"), ("laundry", "Laundry"), ("other", "Other")]
        case .school:
            return [("stationery", "Stationery"), ("books", "Books"),
                    ("tech", "Tech"), ("clothing", "Clothing"), ("other", "Other")]
        case .pharmacy:
            return [("medicine", "Medicine"), ("vitamins", "Vitamins"),
                    ("first_aid", "First Aid"), ("personal_care", "Personal Care"),
                    ("other", "Other")]
        case .pet:
            return [("pet_food", "Food"), ("toys", "Toys"), ("grooming", "Grooming"),
                    ("health", "Health"), ("other", "Other")]
        case .travel:
            return [("clothing", "Clothing"), ("toiletries", "Toiletries"),
                    ("documents", "Documents"), ("tech", "Tech"), ("other", "Other")]
        case .hardware:
            return [("tools", "Tools"), ("materials", "Materials"), ("paint", "Paint"),
                    ("plumbing_electrical", "Plumbing & Electrical"), ("other", "Other")]
        case .clothing:
            return [("tops", "Tops"), ("bottoms", "Bottoms"), ("shoes", "Shoes"),
                    ("accessories", "Accessories"), ("other", "Other")]
        case .other:
            return [("general", "General"), ("gifts", "Gifts"),
                    ("household", "Household"), ("personal_care", "Personal Care"),
                    ("other", "Other")]
        }
    }

    /// Display label for a stored category value on a given list type.
    /// Unknown values (e.g. legacy broad categories) render capitalized.
    static func displayName(for value: String, listType: ShoppingListType) -> String {
        options(for: listType).first { $0.value == value }?.label
            ?? ShoppingCategory(rawValue: value)?.displayName
            ?? value.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// Auto-detect a category for an item name within the list type's set.
    static func detect(from name: String, for type: ShoppingListType) -> String {
        let n = name.lowercased()
        switch type {
        case .groceries:
            return GrocerySubcategory.detect(from: name).rawValue
        case .birthday:
            if containsAny(n, ["gift", "present", "toy", "lego", "game", "card"]) { return "gifts" }
            if containsAny(n, ["cake", "cupcake", "candle", "cookie", "candy", "ice cream"]) { return "cake_treats" }
            if containsAny(n, ["balloon", "banner", "streamer", "confetti", "decor"]) { return "decorations" }
            if containsAny(n, ["plate", "cup", "napkin", "fork", "tablecloth", "party hat"]) { return "party_supplies" }
            if containsAny(n, ["juice", "soda", "pizza", "snack", "chips"]) { return "food_drinks" }
            if containsAny(n, ["piñata", "pinata", "craft", "activity"]) { return "activities" }
            return "other"
        case .holiday:
            if containsAny(n, ["ornament", "lights", "wreath", "tree", "garland", "decor"]) { return "decorations" }
            if containsAny(n, ["gift", "present", "stocking", "toy"]) { return "gifts" }
            if containsAny(n, ["turkey", "ham", "cookie", "cider", "eggnog", "food", "drink"]) { return "food_drinks" }
            if containsAny(n, ["sweater", "pajama", "costume"]) { return "clothing" }
            return "other"
        case .movies:
            if containsAny(n, ["popcorn", "chips", "candy", "snack", "cookie"]) { return "snacks" }
            if containsAny(n, ["soda", "juice", "water", "drink"]) { return "beverages" }
            if containsAny(n, ["movie", "film", "show", "rental", "ticket"]) { return "movies_shows" }
            return "other"
        case .household:
            if containsAny(n, ["detergent", "soap", "cleaner", "bleach", "sponge", "disinfect", "windex", "lysol"]) { return "cleaning" }
            if containsAny(n, ["foil", "wrap", "bag", "container", "foil", "ziplock"]) { return "kitchen" }
            if containsAny(n, ["toilet", "tissue", "paper towel", "napkin"]) { return "bathroom" }
            if containsAny(n, ["laundry", "fabric", "dryer", "stain"]) { return "laundry" }
            return "other"
        case .school:
            if containsAny(n, ["pencil", "pen", "marker", "crayon", "glue", "scissor", "eraser", "ruler", "notebook", "folder", "paper"]) { return "stationery" }
            if containsAny(n, ["book", "novel", "textbook"]) { return "books" }
            if containsAny(n, ["calculator", "usb", "drive", "headphone", "charger", "tablet", "laptop"]) { return "tech" }
            if containsAny(n, ["uniform", "shirt", "shoes", "backpack"]) { return "clothing" }
            return "other"
        case .pharmacy:
            if containsAny(n, ["medicine", "tylenol", "ibuprofen", "advil", "cough", "cold", "allergy", "prescription"]) { return "medicine" }
            if containsAny(n, ["vitamin", "supplement", "probiotic", "melatonin"]) { return "vitamins" }
            if containsAny(n, ["bandaid", "bandage", "gauze", "ointment", "antiseptic", "thermometer"]) { return "first_aid" }
            if containsAny(n, ["shampoo", "toothpaste", "soap", "lotion", "deodorant", "sunscreen"]) { return "personal_care" }
            return "other"
        case .pet:
            if containsAny(n, ["food", "kibble", "treat", "feed"]) { return "pet_food" }
            if containsAny(n, ["toy", "ball", "bone", "chew"]) { return "toys" }
            if containsAny(n, ["shampoo", "brush", "nail", "litter", "groom"]) { return "grooming" }
            if containsAny(n, ["vet", "medicine", "flea", "tick", "vaccine"]) { return "health" }
            return "other"
        case .travel:
            if containsAny(n, ["shirt", "pants", "socks", "underwear", "jacket", "swimsuit"]) { return "clothing" }
            if containsAny(n, ["toothbrush", "toothpaste", "shampoo", "deodorant", "sunscreen", "razor"]) { return "toiletries" }
            if containsAny(n, ["passport", "ticket", "visa", "id", "document"]) { return "documents" }
            if containsAny(n, ["charger", "adapter", "headphone", "power bank", "camera"]) { return "tech" }
            return "other"
        case .hardware:
            if containsAny(n, ["hammer", "screwdriver", "drill", "wrench", "saw", "tape measure"]) { return "tools" }
            if containsAny(n, ["nail", "screw", "wood", "lumber", "board", "plywood"]) { return "materials" }
            if containsAny(n, ["paint", "brush", "roller", "primer"]) { return "paint" }
            if containsAny(n, ["pipe", "wire", "outlet", "bulb", "switch", "faucet"]) { return "plumbing_electrical" }
            return "other"
        case .clothing:
            if containsAny(n, ["shirt", "blouse", "top", "sweater", "jacket", "hoodie"]) { return "tops" }
            if containsAny(n, ["pants", "jeans", "shorts", "skirt", "legging"]) { return "bottoms" }
            if containsAny(n, ["shoe", "sneaker", "boot", "sandal", "sock"]) { return "shoes" }
            if containsAny(n, ["hat", "belt", "scarf", "watch", "jewelry", "bag"]) { return "accessories" }
            return "other"
        case .other:
            return "general"
        }
    }

    private static func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
