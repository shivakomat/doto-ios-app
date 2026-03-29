import Foundation

struct Family: Codable, Identifiable {
    let id: String
    let name: String
    let inviteCode: String
    var members: [Profile]
    let createdAt: Date
}
