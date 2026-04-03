import Foundation

// MARK: - Notification Preferences
struct NotificationPreferences: Codable {
    var taskAssigned: Bool
    var taskOverdue: Bool
    var taskCompleted: Bool
    var scheduleConflict: Bool
    var rewardPending: Bool
    var rewardApproved: Bool
    var streakAtRisk: Bool
    var bonusPoints: Bool
    var weeklyDigest: Bool
    
    static var `default`: NotificationPreferences {
        NotificationPreferences(
            taskAssigned: true,
            taskOverdue: true,
            taskCompleted: true,
            scheduleConflict: true,
            rewardPending: true,
            rewardApproved: true,
            streakAtRisk: true,
            bonusPoints: true,
            weeklyDigest: false
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case taskAssigned = "task_assigned"
        case taskOverdue = "task_overdue"
        case taskCompleted = "task_completed"
        case scheduleConflict = "schedule_conflict"
        case rewardPending = "reward_pending"
        case rewardApproved = "reward_approved"
        case streakAtRisk = "streak_at_risk"
        case bonusPoints = "bonus_points"
        case weeklyDigest = "weekly_digest"
    }
}

// MARK: - API Response Models
struct DeleteAccountResponse: Decodable {
    let deleted: Bool
    let familyDeleted: Bool?
}

struct LeaveFamilyResponse: Decodable {
    let left: Bool
}

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var family: Family?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // New properties for notifications and confirmation dialogs
    @Published var notifications: NotificationPreferences = .default
    @Published var showDeleteConfirm = false
    @Published var showLeaveConfirm = false

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
                "/api/profiles/me",
                body: UpdateProfileRequest(displayName: displayName, color: color)
            )
            successMessage = "Profile updated"
        } catch APIError.validation(let msg) {
            errorMessage = msg
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

    // MARK: - Notifications

    func loadNotifications() async {
        do {
            let response: NotificationPreferences = try await APIClient.shared.get("/api/profiles/me/notifications")
            notifications = response
        } catch {
            // Keep defaults if fetch fails
        }
    }

    func saveNotifications() async {
        do {
            let _: EmptyResponse = try await APIClient.shared.put(
                "/api/profiles/me/notifications",
                body: notifications
            )
            successMessage = "Notification preferences saved"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Account Management

    func deleteAccount(authVM: AuthViewModel) async {
        isLoading = true; defer { isLoading = false }
        do {
            try await APIClient.shared.delete("/api/profiles/me")
            await authVM.logout()
        } catch APIError.serverError(let msg) {
            errorMessage = msg
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveFamily(authVM: AuthViewModel) async {
        isLoading = true; defer { isLoading = false }
        do {
            let response: LeaveFamilyResponse = try await APIClient.shared.post("/api/families/leave")
            if response.left {
                await authVM.logout()
            }
        } catch APIError.serverError(let msg) {
            errorMessage = msg
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
