import Foundation

struct DotoTask: Codable, Identifiable {
    let id: String
    let familyId: String?
    var title: String
    var notes: String?
    var assignedTo: String?
    var priority: String?
    var status: String?
    var points: Int
    var dueAt: Date?
    var repeat_: String?
    var completedAt: Date?
    var rewardGoalId: String?
    let createdBy: String?
    let createdAt: Date?
    let updatedAt: Date?

    var isOverdue: Bool {
        guard let due = dueAt else { return false }
        return status != "done" && due < Date()
    }
    var isDueToday: Bool {
        guard let due = dueAt else { return false }
        return status != "done" && Calendar.current.isDateInToday(due)
    }
    var isDone: Bool { status == "done" }

    private enum CodingKeys: String, CodingKey {
        case id, familyId, title, assignedTo, priority, status
        case notes, points, dueAt, completedAt, rewardGoalId, createdBy, createdAt, updatedAt
        case repeat_ = "repeat"
    }
}
