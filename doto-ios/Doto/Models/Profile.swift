import Foundation

struct Profile: Codable, Identifiable {
    let id: String
    let username: String?
    let displayName: String
    let role: String
    let color: String
    var points: Int
    var streak: Int?
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
}
