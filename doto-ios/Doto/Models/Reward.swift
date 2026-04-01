import Foundation

struct Reward: Codable, Identifiable {
    let id: String
    let familyId: String
    let memberId: String
    var title: String
    var emoji: String?
    var pointsCost: Int
    var catalogItemId: String?
    var status: String
    var requestedAt: Date?
    var approvedBy: String?
    var approvedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    var statusLabel: String {
        switch status {
        case "active":           return "Active"
        case "pending_approval": return "Pending ⏳"
        case "approved":         return "Approved ✓"
        case "redeemed":         return "Redeemed 🎉"
        default:                 return status
        }
    }

    var titleWithEmoji: String {
        if let e = emoji { return "\(e) \(title)" }
        return title
    }
}
