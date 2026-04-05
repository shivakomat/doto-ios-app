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
    case produce    = "produce"
    case vegetables = "vegetables"
    case fruits     = "fruits"
    case dairy      = "dairy"
    case eggs       = "eggs"
    case meat       = "meat"
    case bakery     = "bakery"
    case grains     = "grains"
    case canned     = "canned"
    case condiments = "condiments"
    case household  = "household"
    case frozen     = "frozen"
    case beverages  = "beverages"
    case snacks     = "snacks"
    case other      = "other"

    var emoji: String {
        switch self {
        case .produce:    return "🥦"
        case .vegetables: return "🥬"
        case .fruits:     return "🍎"
        case .dairy:      return "🥛"
        case .eggs:       return "🥚"
        case .meat:       return "🥩"
        case .bakery:     return "🧁"
        case .grains:     return "🌾"
        case .canned:     return "🥫"
        case .condiments: return "🧂"
        case .household:  return "🧹"
        case .frozen:     return "❄️"
        case .beverages:  return "🧃"
        case .snacks:     return "🍿"
        case .other:      return "📦"
        }
    }

    var displayName: String { rawValue.capitalized }

    static func detect(from name: String) -> ShoppingCategory {
        let n = name.lowercased()
        // Check more specific categories first
        if ["egg"].contains(where: n.contains)                                                                                              { return .eggs       }
        if ["vegetable","pepper","cucumber","potato","corn","celery","mushroom","zucchini","peas","beans","garlic","ginger","onion","carrot","broccoli","spinach","lettuce","tomato","cabbage","squash"].contains(where: n.contains) { return .vegetables }
        if ["fruit","orange","grape","strawberry","blueberry","mango","peach","pear","watermelon","lemon","lime","avocado","pineapple","kiwi","apple","banana","cherry","raspberry"].contains(where: n.contains)                    { return .fruits      }
        if ["milk","cheese","yogurt","butter","cream","sour cream"].contains(where: n.contains)                                             { return .dairy       }
        if ["chicken","beef","pork","salmon","tuna","mince","turkey","lamb","shrimp","bacon","sausage","ham","fish"].contains(where: n.contains) { return .meat   }
        if ["bread","rolls","bagels","croissant","muffin","tortilla","bun","pita"].contains(where: n.contains)                              { return .bakery     }
        if ["rice","pasta","noodle","cereal","oat","flour","quinoa","grain","spaghetti","macaroni"].contains(where: n.contains)              { return .grains     }
        if ["canned","soup","tomato sauce","broth","stock"].contains(where: n.contains)                                                     { return .canned     }
        if ["salt","ketchup","mustard","mayo","sauce","vinegar","oil","spice","seasoning","dressing","soy","sriracha","honey","syrup","jam","jelly"].contains(where: n.contains) { return .condiments }
        if ["soap","bags","bleach","detergent","sponge","toilet","paper towel","trash","wrap","foil","napkin"].contains(where: n.contains)   { return .household  }
        if ["frozen","ice cream","pizza"].contains(where: n.contains)                                                                       { return .frozen     }
        if ["water","juice","soda","coffee","tea","beer","wine","drink"].contains(where: n.contains)                                        { return .beverages  }
        if ["chips","cookie","cracker","candy","popcorn","chocolate","granola","bar","pretzel"].contains(where: n.contains)                  { return .snacks     }
        return .other
    }
}
