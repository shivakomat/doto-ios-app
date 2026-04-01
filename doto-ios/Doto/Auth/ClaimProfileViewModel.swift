import Foundation

@MainActor
class ClaimProfileViewModel: ObservableObject {
    @Published var familyPreview: FamilyPreview?
    @Published var claimedProfile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadPreview(code: String) async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            familyPreview = try await APIClient.shared.get(
                "/families/preview/\(code.uppercased())"
            )
        } catch APIError.notFound {
            errorMessage = "Invite code not found."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func claimProfile(
        profileId: String,
        inviteCode: String,
        username: String,
        password: String,
        authVM: AuthViewModel
    ) async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let res: AuthResponse = try await APIClient.shared.post(
                "/auth/claim-profile",
                body: ClaimProfileRequest(
                    profileId: profileId,
                    inviteCode: inviteCode.uppercased(),
                    username: username.lowercased(),
                    password: password
                )
            )
            KeychainHelper.saveToken(res.token)
            authVM.currentProfile = res.profile
            claimedProfile = res.profile
        } catch APIError.conflict(let msg) {
            errorMessage = msg
        } catch APIError.validation(let msg) {
            errorMessage = msg
        } catch APIError.notFound {
            errorMessage = "Profile or invite code not found."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeTransition(authVM: AuthViewModel) {
        authVM.state = .ready
    }
}
