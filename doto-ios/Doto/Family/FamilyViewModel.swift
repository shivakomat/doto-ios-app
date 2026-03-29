import Foundation

@MainActor
class FamilyViewModel: ObservableObject {
    @Published var family: Family?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            family = try await APIClient.shared.get("/families/mine")
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static let hexPalette = [
        "#185FA5", "#1D9E75", "#BA7517", "#993556", "#534AB7", "#E24B4A"
    ]

    func addChild(displayName: String) async {
        let nextIndex = (family?.members.count ?? 0) % Self.hexPalette.count
        let color = Self.hexPalette[nextIndex]
        struct AddMemberRequest: Encodable { let displayName: String; let color: String }
        do {
            let member: Profile = try await APIClient.shared.post(
                "/members",
                body: AddMemberRequest(displayName: displayName, color: color)
            )
            family?.members.append(member)
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMember(_ member: Profile) async {
        do {
            try await APIClient.shared.delete("/members/\(member.id)")
            family?.members.removeAll { $0.id == member.id }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
