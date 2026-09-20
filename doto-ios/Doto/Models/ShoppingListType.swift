import SwiftUI

/// Shopping list category — drives the icon shown beside the list name and,
/// for `.groceries`, unlocks aisle-style subcategory grouping.
enum ShoppingListType: String, CaseIterable {
    case groceries, birthday, holiday, movies, household, school,
         pharmacy, pet, travel, hardware, clothing, other

    var label: String {
        switch self {
        case .groceries: return "Groceries"
        case .birthday:  return "Birthday"
        case .holiday:   return "Holiday"
        case .movies:    return "Movies"
        case .household: return "Household Supplies"
        case .school:    return "School Supplies"
        case .pharmacy:  return "Pharmacy / Health"
        case .pet:       return "Pet Supplies"
        case .travel:    return "Travel / Packing"
        case .hardware:  return "Hardware / DIY"
        case .clothing:  return "Clothing"
        case .other:     return "Other"
        }
    }

    var icon: String {
        switch self {
        case .groceries: return "cart.fill"
        case .birthday:  return "gift.fill"
        case .holiday:   return "sparkles"
        case .movies:    return "popcorn.fill"
        case .household: return "house.fill"
        case .school:    return "backpack.fill"
        case .pharmacy:  return "cross.case.fill"
        case .pet:       return "pawprint.fill"
        case .travel:    return "suitcase.fill"
        case .hardware:  return "wrench.and.screwdriver.fill"
        case .clothing:  return "tshirt.fill"
        case .other:     return "checklist"
        }
    }

    /// Fallback for symbols not present on the minimum deployment target.
    private var fallbackIcon: String {
        switch self {
        case .movies:   return "film.fill"
        case .school:   return "book.fill"
        case .pet:      return "hare.fill"
        case .hardware: return "hammer.fill"
        case .other:    return "list.bullet"
        default:        return icon
        }
    }

    var resolvedIcon: String {
        UIImage(systemName: icon) != nil ? icon : fallbackIcon
    }

    var color: Color {
        switch self {
        case .groceries: return .memberGreen
        case .birthday:  return .memberRed
        case .holiday:   return .memberPurple
        case .movies:    return .memberAmber
        case .household: return .memberBlue
        case .school:    return .memberPurple
        case .pharmacy:  return .memberGreen
        case .pet:       return .memberRed
        case .travel:    return .memberBlue
        case .hardware:  return .memberAmber
        case .clothing:  return .memberPurple
        case .other:     return .textMuted
        }
    }
}
