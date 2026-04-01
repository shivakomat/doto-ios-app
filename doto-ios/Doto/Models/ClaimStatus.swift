import Foundation

struct ClaimStatus: Codable {
    let profileId: String
    let displayName: String
    let isClaimed: Bool
    let username: String?
}
