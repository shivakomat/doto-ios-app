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

    var durationMinutes: Int {
        Int(endAt.timeIntervalSince(startAt) / 60)
    }

    var durationHours: Double {
        Double(durationMinutes) / 60.0
    }

    var startHour: Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: startAt)
        return Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60.0
    }

    var timeRangeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: startAt)) – \(f.string(from: endAt))"
    }

    private enum CodingKeys: String, CodingKey {
        case id, familyId, title, description, startAt, endAt
        case location, color, assignedTo, createdBy, createdAt, updatedAt
        case repeat_ = "repeat"
    }
}
