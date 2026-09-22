import SwiftUI
import UIKit

/// Reward catalog category — drives the icon chip shown on catalog cards.
/// The icon is derived from the stored `category` value (no separate icon
/// field), and colors come from the shared member palette — same convention
/// as `ShoppingListType` and `TaskIconCatalog`.
enum RewardCategory: String, CaseIterable {
    case screenTime         = "screen_time"
    case treatsFood         = "treats_food"
    case money              = "money"
    case toysShopping       = "toys_shopping"
    case outing             = "outing"
    case movieEntertainment = "movie_entertainment"
    case sleepoverFriends   = "sleepover_friends"
    case lateBedtime        = "late_bedtime"
    case chooseActivity     = "choose_activity"
    case skipChore          = "skip_chore"
    case specialPrivilege   = "special_privilege"
    case custom             = "custom"

    var label: String {
        switch self {
        case .screenTime:         return "Screen Time"
        case .treatsFood:         return "Treats & Food"
        case .money:              return "Money"
        case .toysShopping:       return "Toys & Shopping"
        case .outing:             return "Outing"
        case .movieEntertainment: return "Movie & Fun"
        case .sleepoverFriends:   return "Sleepover & Friends"
        case .lateBedtime:        return "Late Bedtime"
        case .chooseActivity:     return "Choose Activity"
        case .skipChore:          return "Skip a Chore"
        case .specialPrivilege:   return "Special Privilege"
        case .custom:             return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .screenTime:         return "iphone"
        case .treatsFood:         return "fork.knife"
        case .money:              return "dollarsign.circle.fill"
        case .toysShopping:       return "bag.fill"
        case .outing:             return "car.fill"
        case .movieEntertainment: return "theatermasks.fill"
        case .sleepoverFriends:   return "person.2.fill"
        case .lateBedtime:        return "moon.stars.fill"
        case .chooseActivity:     return "star.fill"
        case .skipChore:          return "checkmark.seal.fill"
        case .specialPrivilege:   return "wand.and.stars"
        case .custom:             return "gift.fill"
        }
    }

    /// Fallback for symbols not present on the minimum deployment target.
    private var fallbackIcon: String {
        switch self {
        case .movieEntertainment: return "film.fill"
        case .sleepoverFriends:   return "person.fill"
        case .lateBedtime:        return "moon.fill"
        case .skipChore:          return "checkmark.circle.fill"
        case .specialPrivilege:   return "sparkles"
        case .money:              return "dollarsign.circle"
        default:                  return icon
        }
    }

    var resolvedIcon: String {
        UIImage(systemName: icon) != nil ? icon : fallbackIcon
    }

    var color: Color {
        switch self {
        case .screenTime:         return .memberBlue
        case .treatsFood:         return .memberMaroon
        case .money:              return .memberGreen
        case .toysShopping:       return .memberRed
        case .outing:             return .memberAmber
        case .movieEntertainment: return .memberPurple
        case .sleepoverFriends:   return .memberBlue
        case .lateBedtime:        return .memberPurple
        case .chooseActivity:     return .memberAmber
        case .skipChore:          return .memberGreen
        case .specialPrivilege:   return .memberMaroon
        case .custom:             return .textMuted
        }
    }

    /// Resolve a stored category string; unknown/missing values fall back to `.custom`.
    static func from(_ value: String?) -> RewardCategory {
        value.flatMap(RewardCategory.init(rawValue:)) ?? .custom
    }
}
