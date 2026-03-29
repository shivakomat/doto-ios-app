import Foundation

struct Reward: Codable, Identifiable {
    let id: String
    let familyId: String
    let memberId: String
    var title: String
    var pointsCost: Int
    var status: String
    var requestedAt: Date?
    var approvedBy: String?
    var approvedAt: Date?
    let createdAt: Date
    let updatedAt: Date
}
