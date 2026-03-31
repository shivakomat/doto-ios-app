import Foundation

enum AppState {
    case unauthenticated
    case noFamily
    case ready
}

extension Notification.Name {
    static let dotoUnauthorized = Notification.Name("DotoUnauthorized")
}

struct AuthResponse: Decodable  { let token: String; let profile: Profile }
struct LoginRequest: Encodable    { let username: String; let password: String }
struct RegisterRequest: Encodable {
    let username: String
    let password: String
    let displayName: String
    let role: String
    let inviteCode: String?
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var state: AppState = .unauthenticated
    @Published var currentProfile: Profile?
    @Published var errorMessage: String?
    @Published var isLoading = false

    init() {
        NotificationCenter.default.addObserver(
            forName: .dotoUnauthorized, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.logout() }
        }
    }

    func restoreSession() async {
        guard KeychainHelper.loadToken() != nil else { state = .unauthenticated; return }
        do {
            let profile: Profile = try await APIClient.shared.get("/auth/me")
            currentProfile = profile
            state = profile.familyId == nil ? .noFamily : .ready
        } catch {
            KeychainHelper.deleteToken()
            state = .unauthenticated
        }
    }

    func login(username: String, password: String) async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let res: AuthResponse = try await APIClient.shared.post(
                "/auth/login",
                body: LoginRequest(username: username, password: password)
            )
            KeychainHelper.saveToken(res.token)
            currentProfile = res.profile
            state = res.profile.familyId == nil ? .noFamily : .ready
        } catch {
            errorMessage = "Incorrect username or password."
        }
    }

    func register(
        username: String,
        password: String,
        displayName: String,
        role: String,
        inviteCode: String?
    ) async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let res: AuthResponse = try await APIClient.shared.post(
                "/auth/register",
                body: RegisterRequest(
                    username: username,
                    password: password,
                    displayName: displayName,
                    role: role,
                    inviteCode: inviteCode
                )
            )
            KeychainHelper.saveToken(res.token)
            currentProfile = res.profile
            state = res.profile.familyId == nil ? .noFamily : .ready
        } catch APIError.conflict(_) {
            errorMessage = "That username is already taken. Try a different one."
        } catch APIError.notFound {
            errorMessage = "The invite code is no longer valid. Go back and try again."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshProfile() async {
        do {
            let profile: Profile = try await APIClient.shared.get("/auth/me")
            currentProfile = profile
            if profile.familyId != nil { state = .ready }
        } catch {}
    }

    func refreshCurrentProfileOnly() async {
        do {
            let profile: Profile = try await APIClient.shared.get("/auth/me")
            currentProfile = profile
        } catch {}
    }

    func logout() {
        KeychainHelper.deleteToken()
        currentProfile = nil
        state = .unauthenticated
    }
}
