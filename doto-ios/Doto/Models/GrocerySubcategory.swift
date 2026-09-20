import SwiftUI

/// Aisle-style grouping for items on a Groceries list. Ordered for display.
enum GrocerySubcategory: String, CaseIterable {
    case produce, dairyEggs = "dairy_eggs", bakery, meatSeafood = "meat_seafood",
         frozen, pantry, snacks, beverages, condiments, household,
         personalCare = "personal_care", baby, other

    var displayName: String {
        switch self {
        case .produce:      return "Produce"
        case .dairyEggs:    return "Dairy & Eggs"
        case .bakery:       return "Bakery"
        case .meatSeafood:  return "Meat & Seafood"
        case .frozen:       return "Frozen"
        case .pantry:       return "Pantry & Dry Goods"
        case .snacks:       return "Snacks"
        case .beverages:    return "Beverages"
        case .condiments:   return "Condiments & Sauces"
        case .household:    return "Household & Cleaning"
        case .personalCare: return "Personal Care"
        case .baby:         return "Baby"
        case .other:        return "Other"
        }
    }

    var icon: String {
        switch self {
        case .produce:      return "leaf.fill"
        case .dairyEggs:    return "carton.fill"
        case .bakery:       return "birthday.cake.fill"
        case .meatSeafood:  return "fish.fill"
        case .frozen:       return "snowflake"
        case .pantry:       return "archivebox.fill"
        case .snacks:       return "popcorn.fill"
        case .beverages:    return "waterbottle.fill"
        case .condiments:   return "drop.fill"
        case .household:    return "sparkles"
        case .personalCare: return "heart.fill"
        case .baby:         return "figure.and.child.holdinghands"
        case .other:        return "ellipsis.circle.fill"
        }
    }

    /// Fallback for symbols not present on the minimum deployment target.
    private var fallbackIcon: String {
        switch self {
        case .dairyEggs:   return "cup.and.saucer.fill"
        case .bakery:      return "takeoutbag.and.cup.and.straw.fill"
        case .snacks:      return "birthday.cake.fill"
        case .beverages:   return "cup.and.saucer.fill"
        case .baby:        return "face.smiling"
        case .meatSeafood: return "fork.knife"
        default:           return icon
        }
    }

    var resolvedIcon: String {
        UIImage(systemName: icon) != nil ? icon : fallbackIcon
    }

    /// Auto-detect the aisle for an item name. Checks subcategory-specific
    /// keywords first (baby, snacks), then folds the existing
    /// `ShoppingCategory.detect` result into the 13 aisles.
    static func detect(from name: String) -> GrocerySubcategory {
        let n = name.lowercased()

        let babyKeywords = [
            "diaper", "formula", "baby food", "baby wipe", "wipes",
            "pacifier", "teething", "baby cereal", "nappy",
        ]
        if babyKeywords.contains(where: n.contains) { return .baby }

        let snackKeywords = [
            "chips", "chip", "crackers", "popcorn", "pretzel", "granola bar",
            "trail mix", "nuts", "candy bar", "gummy", "fruit snack",
            "cookie", "cookies", "snack",
        ]
        if snackKeywords.contains(where: n.contains) { return .snacks }

        switch ShoppingCategory.detect(from: name) {
        case .vegetables, .fruits:        return .produce
        case .dairy:                      return .dairyEggs
        case .bakery:                     return .bakery
        case .meat:                       return .meatSeafood
        case .frozen:                     return .frozen
        case .grains, .canned:            return .pantry
        case .desserts:                   return .snacks
        case .beverages:                  return .beverages
        case .condiments:                 return .condiments
        case .household:                  return .household
        case .personalCare:               return .personalCare
        case .electronics, .gifts, .flowers, .other:
            return .other
        }
    }
}
