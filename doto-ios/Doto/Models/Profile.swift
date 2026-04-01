import Foundation

struct Profile: Codable, Identifiable {
    let id: String
    let username: String?
    let displayName: String
    let role: String
    let color: String
    var pointsTotal: Int
    var pointsBalance: Int
    var streak: Int?
    var streakStatus: String?
    var streakGraceUsed: Bool?
    var lastStreakDate: String?
    let familyId: String?
    let isAuthAccount: Bool?
    let createdAt: Date?

    var isParent: Bool { role == "parent" }
    var isChild: Bool  { role == "child"  }

    var initials: String {
        displayName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined().uppercased()
    }

    var streakEmoji: String {
        switch streakStatus {
        case "active": return "🔥"
        case "grace":  return "🔸"
        default:       return ""
        }
    }

    var streakLabel: String {
        switch streakStatus {
        case "active": return "\(streak ?? 0) days"
        case "grace":  return "\(streak ?? 0) grace"
        default:       return "—"
        }
    }
}
