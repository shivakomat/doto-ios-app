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
    let notificationPreferences: [String: String]?

    private enum CodingKeys: String, CodingKey {
        case id, username, displayName, role, color
        case pointsTotal, pointsBalance, points
        case streak, streakStatus, streakGraceUsed, lastStreakDate
        case familyId, isAuthAccount, createdAt, notificationPreferences
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(String.self, forKey: .id)
        username        = try c.decodeIfPresent(String.self, forKey: .username)
        displayName     = try c.decode(String.self, forKey: .displayName)
        role            = try c.decode(String.self, forKey: .role)
        color           = try c.decode(String.self, forKey: .color)
        let fallback    = try c.decodeIfPresent(Int.self, forKey: .points) ?? 0
        pointsTotal     = try c.decodeIfPresent(Int.self, forKey: .pointsTotal) ?? fallback
        pointsBalance   = try c.decodeIfPresent(Int.self, forKey: .pointsBalance) ?? fallback
        streak          = try c.decodeIfPresent(Int.self, forKey: .streak)
        streakStatus    = try c.decodeIfPresent(String.self, forKey: .streakStatus)
        streakGraceUsed = try c.decodeIfPresent(Bool.self, forKey: .streakGraceUsed)
        lastStreakDate  = try c.decodeIfPresent(String.self, forKey: .lastStreakDate)
        familyId        = try c.decodeIfPresent(String.self, forKey: .familyId)
        isAuthAccount   = try c.decodeIfPresent(Bool.self, forKey: .isAuthAccount)
        createdAt       = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        notificationPreferences = try c.decodeIfPresent([String: String].self, forKey: .notificationPreferences)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(username, forKey: .username)
        try c.encode(displayName, forKey: .displayName)
        try c.encode(role, forKey: .role)
        try c.encode(color, forKey: .color)
        try c.encode(pointsTotal, forKey: .pointsTotal)
        try c.encode(pointsBalance, forKey: .pointsBalance)
        try c.encodeIfPresent(streak, forKey: .streak)
        try c.encodeIfPresent(streakStatus, forKey: .streakStatus)
        try c.encodeIfPresent(streakGraceUsed, forKey: .streakGraceUsed)
        try c.encodeIfPresent(lastStreakDate, forKey: .lastStreakDate)
        try c.encodeIfPresent(familyId, forKey: .familyId)
        try c.encodeIfPresent(isAuthAccount, forKey: .isAuthAccount)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(notificationPreferences, forKey: .notificationPreferences)
    }

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
