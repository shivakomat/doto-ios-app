import Foundation

struct FamilyPreview: Codable {
    let familyName: String
    let memberCount: Int
    let inviteCode: String
    let unclaimedChildren: [UnclaimedChild]
}
