import Foundation

// MARK: - Leaderboard

struct LeaderboardEntry: Decodable, Identifiable {
    var id: String { memberId }
    let memberId: String
    let displayName: String
    let color: String
    let role: String
    let weeklyPoints: Int
    let totalPoints: Int
    let rank: Int
    var streak: Int?
    var streakStatus: String?
}

struct Leaderboard: Decodable {
    let weekStart: Date
    let weekEnd: Date
    let entries: [LeaderboardEntry]
}

// MARK: - Points History

struct PointsHistoryEntry: Decodable, Identifiable {
    let id: String
    let eventType: String
    let amount: Int
    let note: String?
    let referenceId: String?
    let createdAt: Date

    var isEarning: Bool { amount > 0 }

    var icon: String {
        switch eventType {
        case "task":      return "checkmark.circle.fill"
        case "bonus":     return "gift.fill"
        case "redeem":    return "ticket.fill"
        case "milestone": return "medal.fill"
        default:          return "circle.fill"
        }
    }

    var iconColor: String {
        switch eventType {
        case "task":      return "#1D9E75"
        case "bonus":     return "#185FA5"
        case "redeem":    return "#E24B4A"
        case "milestone": return "#185FA5"
        default:          return "#94A3B8"
        }
    }
}

struct PointsHistoryResponse: Decodable {
    let memberId: String
    let displayName: String
    let pointsTotal: Int
    let pointsBalance: Int
    let entries: [PointsHistoryEntry]
    let hasMore: Bool
    let nextBefore: Date?
}

// MARK: - Reward Catalog

struct RewardCatalogItem: Codable, Identifiable {
    let id: String
    let familyId: String
    var title: String
    var emoji: String?
    var pointsCost: Int
    let createdBy: String
    let createdAt: Date

    var titleWithEmoji: String {
        if let e = emoji { return "\(e) \(title)" }
        return title
    }
}

// MARK: - Bonus Points

struct BonusPointsRequest: Encodable {
    let amount: Int
    let note: String?
}

struct BonusPointsResponse: Decodable {
    let member: MemberPointsUpdate
    let historyEntry: PointsHistoryEntry
    let newMilestone: String?
}

struct MemberPointsUpdate: Decodable {
    let id: String
    let pointsTotal: Int
    let pointsBalance: Int
}

// MARK: - Milestones

struct Milestone {
    let value: String
    let displayName: String
    let emoji: String
    let threshold: Int

    static let all: [Milestone] = [
        Milestone(value: "bronze",  displayName: "Getting Started", emoji: "🥉", threshold: 100),
        Milestone(value: "silver",  displayName: "On a Roll",       emoji: "🥈", threshold: 250),
        Milestone(value: "gold",    displayName: "Star Helper",     emoji: "🥇", threshold: 500),
        Milestone(value: "diamond", displayName: "Family Legend",   emoji: "💎", threshold: 1000),
    ]

    static func from(_ value: String) -> Milestone? {
        all.first { $0.value == value }
    }
}

// MARK: - Family Goal

struct FamilyGoalContribution: Decodable {
    let memberId: String
    let displayName: String
    let color: String
    let weeklyPoints: Int
}

struct FamilyGoal: Decodable, Identifiable {
    let id: String
    let familyId: String
    var title: String
    var emoji: String?
    var pointsTarget: Int
    var status: String
    let contributions: [FamilyGoalContribution]
    let combinedWeeklyPoints: Int
    let estimatedWeeks: Int
    let createdAt: Date
}

struct MilestoneWrapper: Identifiable {
    var id: String { value }
    let value: String
}
