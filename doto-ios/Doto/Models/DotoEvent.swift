import Foundation

struct DotoEvent: Codable, Identifiable {
    let id: String
    let familyId: String?
    var title: String
    var description: String?
    var startAt: Date
    var endAt: Date
    var location: String?
    var color: String?
    var repeat_: String?
    var assignedTo: [String]
    let createdBy: String?
    let createdAt: Date?
    let updatedAt: Date?

    var isConflicting: Bool = false

    private enum CodingKeys: String, CodingKey {
        case id, familyId, title, description, startAt, endAt
        case location, color, assignedTo, createdBy, createdAt, updatedAt
        case repeat_ = "repeat"
    }
}
