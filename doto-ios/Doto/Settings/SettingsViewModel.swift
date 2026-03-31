import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var family: Family?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    func loadFamily() async {
        isLoading = true; defer { isLoading = false }
        do {
            family = try await APIClient.shared.get("/families/mine")
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProfile(displayName: String, color: String) async {
        struct UpdateProfileRequest: Encodable { let displayName: String; let color: String }
        do {
            let _: Profile = try await APIClient.shared.patch(
                "/auth/profile",
                body: UpdateProfileRequest(displayName: displayName, color: color)
            )
            successMessage = "Profile updated"
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateFamilyName(_ name: String) async {
        struct UpdateFamilyRequest: Encodable { let name: String }
        do {
            let updated: Family = try await APIClient.shared.patch(
                "/families/mine",
                body: UpdateFamilyRequest(name: name)
            )
            family = updated
            successMessage = "Family name updated"
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func changePassword(current: String, new: String) async {
        struct ChangePasswordRequest: Encodable { let currentPassword: String; let newPassword: String }
        do {
            let _: EmptyResponse = try await APIClient.shared.patch(
                "/auth/change-password",
                body: ChangePasswordRequest(currentPassword: current, newPassword: new)
            )
            successMessage = "Password changed"
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
