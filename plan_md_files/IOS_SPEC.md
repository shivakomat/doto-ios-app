# Doto — iOS Specification
**Version:** 2.0 (updated from wireframe review)
**Language:** Swift 5.9
**UI Framework:** SwiftUI
**Architecture:** MVVM
**Min iOS:** 16.0

---

## 1. Design System

### 1.1 Colour Palette

All colours are defined in `Shared/Extensions/Color+Doto.swift`.

```swift
extension Color {
    // Member colours — auto-assigned in this exact order
    static let memberBlue   = Color(hex: "#185FA5")  // index 0 — creator always gets this
    static let memberGreen  = Color(hex: "#1D9E75")  // index 1
    static let memberAmber  = Color(hex: "#BA7517")  // index 2
    static let memberMaroon = Color(hex: "#993556")  // index 3
    static let memberPurple = Color(hex: "#534AB7")  // index 4
    static let memberRed    = Color(hex: "#E24B4A")  // index 5

    static let memberPalette: [Color] = [
        .memberBlue, .memberGreen, .memberAmber,
        .memberMaroon, .memberPurple, .memberRed
    ]

    // Static hex values for the same palette (used when passing to API)
    static let memberHexPalette = [
        "#185FA5", "#1D9E75", "#BA7517",
        "#993556", "#534AB7", "#E24B4A"
    ]

    // App chrome
    static let appNavy      = Color(hex: "#1E2761")  // header background
    static let appNavySub   = Color(hex: "#CADCFC")  // header subtext

    // Semantic
    static let conflictBg     = Color(hex: "#FAEEDA")
    static let conflictBorder = Color(hex: "#F0C070")
    static let conflictText   = Color(hex: "#633806")
    static let overdueBg      = Color(hex: "#FCEBEB")
    static let overdueText    = Color(hex: "#791F1F")
    static let doneBg         = Color(hex: "#EAF3DE")
    static let doneText       = Color(hex: "#27500A")
    static let dueTodayBg     = Color(hex: "#FAEEDA")
    static let dueTodayText   = Color(hex: "#633806")
    static let selectedDayBg  = Color(hex: "#DBEAFE")

    // Utility
    static let screenBg     = Color(hex: "#F8FAFC")
    static let cardBorder   = Color(hex: "#E2E8F0")
    static let textPrimary  = Color(hex: "#1E293B")
    static let textSecondary = Color(hex: "#64748B")
    static let textMuted    = Color(hex: "#94A3B8")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red:   Double((int & 0xFF0000) >> 16) / 255,
            green: Double((int & 0x00FF00) >> 8)  / 255,
            blue:  Double(int & 0x0000FF)          / 255
        )
    }
}
```

### 1.2 Typography
System font stack only (`-apple-system` / `SF Pro`). No custom fonts. Match the wireframe exactly.

### 1.3 Icons
Use SF Symbols throughout. Emoji are used only where the wireframe explicitly shows them:
- 🔔 notifications onboarding
- 🏆 rewards leaderboard heading
- 🔥 streaks
- 🥇🥈🥉 leaderboard medals
- ⚡ AI conflict card label
- ⚠ conflict prefix on events
- 📅 ✅ 🛒 FAB bottom sheet options
- 👋 welcome card
- Category emojis: 🥦 🥛 🥩 🧁 🧹 ❄️ 📦

For nav bar, tab bar, and controls — use SF Symbols.

### 1.4 Screen Header Pattern
Every main screen uses the dark navy header:
```swift
struct DotoNavHeader: View {
    let title: String
    var trailing: (() -> AnyView)? = nil

    var body: some View {
        ZStack {
            Color.appNavy.ignoresSafeArea(edges: .top)
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                trailing?()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(height: 44)
    }
}
```

### 1.5 Tab Bar
5 tabs for parents. **3 tabs for children** (Home, Tasks, Rewards only).
Active: blue `#185FA5` text + 2px blue dot above label. Inactive: `#94A3B8` text + gray dot.

---

## 2. App Entry Point & Navigation

### 2.1 App States

```swift
enum AppState {
    case unauthenticated        // no JWT in Keychain
    case noFamily               // valid JWT, profile.familyId == nil
    case ready                  // valid JWT + familyId set → show tabs
}
```

### 2.2 `DotoApp.swift`
```swift
@main
struct DotoApp: App {
    @StateObject private var authVM = AuthViewModel()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(authVM)
        }
    }
}
```

### 2.3 `RootView.swift`
```swift
struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    var body: some View {
        Group {
            switch authVM.state {
            case .unauthenticated: AuthView()
            case .noFamily:        FamilySetupView()
            case .ready:           MainTabView()
            }
        }
        .task { await authVM.restoreSession() }
    }
}
```

---

## 3. Folder Structure

```
doto-ios/
├── DotoApp.swift
├── Config/
│   └── APIConfig.swift
├── Networking/
│   ├── APIClient.swift
│   └── APIError.swift
├── Auth/
│   ├── KeychainHelper.swift
│   ├── AuthViewModel.swift
│   └── AuthView.swift              ← combined login/register with tab toggle
├── Onboarding/
│   ├── FamilySetupView.swift
│   └── NotificationsOnboardingView.swift
├── Models/
│   ├── Profile.swift
│   ├── Family.swift
│   ├── DotoEvent.swift
│   ├── DotoTask.swift
│   ├── ShoppingList.swift
│   ├── ShoppingItem.swift
│   └── Reward.swift
├── Dashboard/
│   ├── DashboardViewModel.swift
│   ├── DashboardView.swift         ← handles both populated + empty states
│   └── FABBottomSheet.swift
├── Schedule/
│   ├── ScheduleViewModel.swift
│   ├── ScheduleView.swift
│   ├── WeekStripView.swift
│   ├── EventDetailSheet.swift
│   └── AddEditEventView.swift
├── Tasks/
│   ├── TasksViewModel.swift
│   ├── TasksView.swift
│   ├── TaskDetailSheet.swift
│   └── AddEditTaskView.swift
├── Shopping/
│   ├── ShoppingViewModel.swift
│   ├── ShoppingView.swift          ← single screen with tab strip + items
│   └── AddItemSheet.swift
├── Rewards/
│   ├── RewardsViewModel.swift
│   └── RewardsView.swift
├── Settings/
│   ├── SettingsViewModel.swift
│   └── SettingsView.swift
├── Family/
│   ├── FamilyViewModel.swift
│   └── FamilyManageView.swift
└── Shared/
    ├── Components/
    │   ├── AvatarView.swift
    │   ├── DotoNavHeader.swift
    │   ├── LoadingView.swift
    │   ├── EmptyStateView.swift
    │   └── MemberCardBackground.swift
    └── Extensions/
        ├── Color+Doto.swift
        └── Date+Formatting.swift
```

---

## 4. Keychain Helper

```swift
// Auth/KeychainHelper.swift
struct KeychainHelper {
    private static let service = "com.doto.app"
    private static let account = "jwt_token"

    static func saveToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteToken() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

---

## 5. Networking Layer

### 5.1 `APIConfig.swift`
```swift
enum APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:9000/api"
    #else
    static let baseURL = "https://api.getdoto.com/api"
    #endif
}
```

### 5.2 `APIError.swift`
```swift
enum APIError: Error, LocalizedError {
    case unauthorized
    case notFound
    case validation(String)
    case conflict(String)
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized:          return "Please log in again."
        case .notFound:              return "Not found."
        case .validation(let msg):   return msg
        case .conflict(let msg):     return msg
        case .serverError(let msg):  return "Server error: \(msg)"
        case .decodingError(let e):  return "Data error: \(e.localizedDescription)"
        case .networkError(let e):   return "Network error: \(e.localizedDescription)"
        case .unknown:               return "An unexpected error occurred."
        }
    }
}
```

### 5.3 `APIClient.swift`
Single shared instance. Injects JWT automatically. Supports query parameters.

```swift
class APIClient {
    static let shared = APIClient()
    private let session = URLSession.shared

    // GET with optional query params
    func get<T: Decodable>(_ path: String, params: [String: String] = [:]) async throws -> T {
        try await request(method: "GET", path: path, params: params, body: nil as EmptyBody?)
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(method: "POST", path: path, params: [:], body: body)
    }

    func put<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(method: "PUT", path: path, params: [:], body: body)
    }

    func patch<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(method: "PATCH", path: path, params: [:], body: body)
    }

    func patch<T: Decodable>(_ path: String) async throws -> T {
        try await request(method: "PATCH", path: path, params: [:], body: nil as EmptyBody?)
    }

    func delete(_ path: String) async throws {
        let _: EmptyResponse = try await request(method: "DELETE", path: path, params: [:], body: nil as EmptyBody?)
    }

    private func request<B: Encodable, T: Decodable>(
        method: String, path: String, params: [String: String], body: B?
    ) async throws -> T {
        var components = URLComponents(string: APIConfig.baseURL + path)!
        if !params.isEmpty {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw APIError.unknown }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainHelper.loadToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = try JSONEncoder.iso8601.encode(body)
        }

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.unknown }

        switch http.statusCode {
        case 200, 201:
            return try JSONDecoder.iso8601.decode(T.self, from: data)
        case 204:
            if let empty = EmptyResponse() as? T { return empty }
            throw APIError.unknown
        case 400:
            let err = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
            throw APIError.validation(err?.message ?? "Validation error")
        case 401, 403:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 409:
            let err = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
            throw APIError.conflict(err?.message ?? "Conflict")
        default:
            let err = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(err?.message ?? "Unknown error")
        }
    }
}

struct EmptyBody: Encodable {}
struct EmptyResponse: Decodable {}
struct APIErrorResponse: Decodable { let code: String; let message: String }

extension JSONEncoder {
    static var iso8601: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }
}

extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }
}
```

---

## 6. Data Models

All structs: `Codable`, `Identifiable`. `Doto` prefix used to avoid Swift naming conflicts.

```swift
// Models/Profile.swift
struct Profile: Codable, Identifiable {
    let id: String
    let email: String?
    let displayName: String
    let role: String           // "parent" | "child"
    let color: String          // hex, e.g. "#185FA5"
    var points: Int            // all-time points (never reset)
    var streak: Int            // current consecutive days streak
    var lastStreakDate: String? // ISO date string "2026-03-27"
    let familyId: String?
    let isAuthAccount: Bool
    let createdAt: Date

    var isParent: Bool { role == "parent" }
    var isChild:  Bool { role == "child"  }
}

// Models/Family.swift
struct Family: Codable, Identifiable {
    let id: String
    let name: String
    let inviteCode: String
    var members: [Profile]
    let createdAt: Date
}

// Models/DotoEvent.swift  — prefixed to avoid SwiftUI.Event collision
struct DotoEvent: Codable, Identifiable {
    let id: String
    let familyId: String
    var title: String
    var description: String?
    var startAt: Date
    var endAt: Date
    var location: String?
    var repeat_: String?       // "none"|"daily"|"weekly"|"monthly" — note underscore avoids keyword
    var assignedTo: [String]   // array of profile IDs
    let createdBy: String
    let createdAt: Date
    let updatedAt: Date

    // Computed: set by client-side conflict detection, not from API
    var isConflicting: Bool = false

    private enum CodingKeys: String, CodingKey {
        case id, familyId, title, description, startAt, endAt
        case location, assignedTo, createdBy, createdAt, updatedAt
        case repeat_ = "repeat"
    }
}

// Models/DotoTask.swift  — prefixed to avoid Swift.Task collision
struct DotoTask: Codable, Identifiable {
    let id: String
    let familyId: String
    var title: String
    var notes: String?
    var assignedTo: String?    // profile ID
    var status: String         // "todo"|"in_progress"|"done"|"cancelled"
    var points: Int            // 1–100
    var dueAt: Date            // required — wireframe marks as required
    var repeat_: String?       // "none"|"daily"|"weekly"
    var completedAt: Date?
    let createdBy: String
    let createdAt: Date
    let updatedAt: Date

    var isOverdue: Bool {
        status != "done" && dueAt < Date()
    }
    var isDueToday: Bool {
        status != "done" && Calendar.current.isDateInToday(dueAt)
    }
    var isDone: Bool { status == "done" }

    private enum CodingKeys: String, CodingKey {
        case id, familyId, title, notes, assignedTo, status
        case points, dueAt, completedAt, createdBy, createdAt, updatedAt
        case repeat_ = "repeat"
    }
}

// Models/ShoppingList.swift
struct ShoppingList: Codable, Identifiable {
    let id: String
    let familyId: String
    var name: String
    let itemCount: Int
    let checkedCount: Int
    let createdBy: String
    let createdAt: Date
    let updatedAt: Date
}

// Models/ShoppingItem.swift
struct ShoppingItem: Codable, Identifiable {
    let id: String
    let listId: String
    var name: String
    var quantity: String?
    var category: String       // see category list below
    var isChecked: Bool
    var checkedBy: String?
    var checkedAt: Date?
    let createdBy: String
    let createdAt: Date
    let updatedAt: Date
}

// Models/Reward.swift
struct Reward: Codable, Identifiable {
    let id: String
    let familyId: String
    let memberId: String
    var title: String
    var pointsCost: Int
    var status: String         // "active"|"pending_approval"|"approved"|"redeemed"
    var requestedAt: Date?
    var approvedBy: String?
    var approvedAt: Date?
    let createdAt: Date
    let updatedAt: Date
}
```

### Shopping Categories
```swift
enum ShoppingCategory: String, CaseIterable {
    case produce   = "produce"
    case dairy     = "dairy"
    case meat      = "meat"
    case bakery    = "bakery"
    case household = "household"
    case frozen    = "frozen"
    case beverages = "beverages"
    case snacks    = "snacks"
    case other     = "other"

    var emoji: String {
        switch self {
        case .produce:   return "🥦"
        case .dairy:     return "🥛"
        case .meat:      return "🥩"
        case .bakery:    return "🧁"
        case .household: return "🧹"
        case .frozen:    return "❄️"
        case .beverages: return "🧃"
        case .snacks:    return "🍿"
        case .other:     return "📦"
        }
    }

    var displayName: String { rawValue.capitalized }

    // Client-side auto-detection by keyword matching
    static func detect(from name: String) -> ShoppingCategory {
        let n = name.lowercased()
        if ["apple","banana","spinach","lettuce","tomato","onion","carrot","broccoli"].contains(where: n.contains) { return .produce }
        if ["milk","cheese","yogurt","butter","cream","eggs"].contains(where: n.contains)                          { return .dairy   }
        if ["chicken","beef","pork","salmon","tuna","mince"].contains(where: n.contains)                          { return .meat    }
        if ["bread","rolls","bagels","croissant"].contains(where: n.contains)                                     { return .bakery  }
        if ["soap","bags","bleach","detergent","sponge","toilet"].contains(where: n.contains)                     { return .household }
        if ["frozen","ice cream","pizza"].contains(where: n.contains)                                             { return .frozen  }
        return .other
    }
}
```

---

## 7. Auth Layer

### 7.1 Unauthorized Notification (global pattern)
All ViewModels use this pattern when catching `.unauthorized`. AuthViewModel listens and logs out.

```swift
// In AuthViewModel.init():
extension Notification.Name {
    static let dotoUnauthorized = Notification.Name("DotoUnauthorized")
}

// Every ViewModel that catches .unauthorized posts:
NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)

// AuthViewModel listens:
NotificationCenter.default.addObserver(
    forName: .dotoUnauthorized, object: nil, queue: .main
) { [weak self] _ in
    self?.logout()
}
```

### 7.2 `AuthViewModel.swift`
```swift
@MainActor
class AuthViewModel: ObservableObject {
    @Published var state: AppState = .unauthenticated
    @Published var currentProfile: Profile?
    @Published var errorMessage: String?
    @Published var isLoading = false

    init() {
        NotificationCenter.default.addObserver(
            forName: .dotoUnauthorized, object: nil, queue: .main
        ) { [weak self] _ in self?.logout() }
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

    func login(email: String, password: String) async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let res: AuthResponse = try await APIClient.shared.post(
                "/auth/login",
                body: LoginRequest(email: email, password: password)
            )
            KeychainHelper.saveToken(res.token)
            currentProfile = res.profile
            state = res.profile.familyId == nil ? .noFamily : .ready
        } catch { errorMessage = error.localizedDescription }
    }

    func register(email: String, password: String, displayName: String) async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let res: AuthResponse = try await APIClient.shared.post(
                "/auth/register",
                body: RegisterRequest(email: email, password: password, displayName: displayName)
            )
            KeychainHelper.saveToken(res.token)
            currentProfile = res.profile
            state = .noFamily
        } catch { errorMessage = error.localizedDescription }
    }

    // Called after FamilySetupView creates or joins a family
    // Must refresh profile from server so familyId is populated
    func refreshProfile() async {
        do {
            let profile: Profile = try await APIClient.shared.get("/auth/me")
            currentProfile = profile
            if profile.familyId != nil { state = .ready }
        } catch {}
    }

    func logout() {
        KeychainHelper.deleteToken()
        currentProfile = nil
        state = .unauthenticated
    }
}

struct AuthResponse: Decodable  { let token: String; let profile: Profile }
struct LoginRequest: Encodable  { let email: String; let password: String }
struct RegisterRequest: Encodable { let email: String; let password: String; let displayName: String }
```

---

## 8. Screen Specifications

---

### Screen 01 — AuthView (Login + Register)
**File:** `Auth/AuthView.swift`
**Route:** Shown when `authVM.state == .unauthenticated`

**Layout:**
- White screen, no header
- Centered logo: "Doto" large bold dark navy + "Family life. Done." italic gray tagline
- `Picker` segmented control: **Sign Up | Sign In** — toggles between the two form variants
- Both variants share: email field + password field
- Sign Up only: display name field (above email) + confirm password field (below password)
- Password fields have show/hide toggle button (eye icon, SF Symbol)
- Primary button: "Create account" (sign up) / "Sign in" (sign in)
- Loading state: button shows `ProgressView` inline + "Creating account..." text, all inputs disabled

**Field rules:**
- Email: `keyboardType(.emailAddress)`, `autocapitalization(.never)`, `autocorrectionDisabled()`. Valid email format required.
- Display name: 1–100 chars. Sign up only.
- Password: min 8 chars.
- Confirm password: must match password. Validated on blur (`.onChange`). Sign up only.

**Inline error states** (shown below the relevant field, in red):
- "Email already in use" — under email field, show "Sign in instead?" link
- "Passwords don't match" — under confirm field, on blur
- "Invalid email or password" — below the button on failed login
- "Something went wrong" — generic network fallback

**Routing on success:**
- Register → `authVM.state = .noFamily` → shows `FamilySetupView`
- Login → if `profile.familyId != nil` → `authVM.state = .ready`, else `.noFamily`

---

### Screen 02 — FamilySetupView
**File:** `Onboarding/FamilySetupView.swift`
**Route:** Shown when `authVM.state == .noFamily`
**Shown once only** — new users only. Returning users with a family never see this.

**Layout:**
- Dark navy header: "Set up your family" + "Step 2 of 3"
- Family name text field (required, max 50 chars, focused on appear)
- Divider
- "Your profile" section:
  - Card (`#EFF6FF` bg, blue border): creator's avatar (blue `#185FA5`, initials) + display name + "(you)" + "Parent" blue badge
- "Invite family members" section:
  - Email input: "Partner's email address..." (optional — sends invite)
  - Two buttons in a 2-column grid: "+ Add child" (→ modal: child name) | "📋 Copy link" (copies invite link, shows "Copied!" toast)
- Hint text: "You can add more people later in Settings" (muted, centered)
- "Continue →" primary button

**On submit:**
1. `POST /api/families` → creates family, gets `inviteCode`
2. If partner email was entered → `POST /api/families/invite` (send email invite)
3. If child was added → `POST /api/members` for the child profile
4. Call `authVM.refreshProfile()` — **required** to populate `profile.familyId` in memory
5. After `refreshProfile()` succeeds → navigate to `NotificationsOnboardingView`

**Note:** Do NOT set `authVM.state = .ready` directly here. Always call `refreshProfile()` first, which reads the updated profile from the server and then sets the state.

**Add child modal fields:**
- Child's name (display name, required)
- Colour auto-assigned (next in palette sequence after creator)

---

### Screen 03 — NotificationsOnboardingView
**File:** `Onboarding/NotificationsOnboardingView.swift`
**Route:** Shown after FamilySetupView — step 3 of 3. Never shown again after first time.

**Layout:**
- No header — full-screen centered content, white background
- 🔔 emoji (44px, centered)
- "Stay in the loop" (14px bold, `#1E293B`)
- Body text: "Get notified when tasks are assigned, schedules conflict, or your weekly digest is ready." (10px, `#64748B`, centered, line height 1.6)
- "Enable notifications" — full-width primary blue button
- "Not now — I'll enable later" — muted gray text link below

**Actions:**
- Enable → call `UNUserNotificationCenter.current().requestAuthorization()` → on grant: store preference in `UserDefaults` as `notificationsEnabled = true` → call `authVM.refreshProfile()` → `authVM.state = .ready`
- Not now → store `UserDefaults` `notificationsEnabled = false` → `authVM.state = .ready`

**Important:** Store whether the user has seen this screen in `UserDefaults` (`hasSeenNotificationsOnboarding = true`) so it never shows again.

---

### Screen 04 — MainTabView
**File:** `MainTabView.swift`

Parent tab bar (5 tabs):
```swift
TabView {
    DashboardView()
        .tabItem { Label("Home",     systemImage: "house.fill") }
    ScheduleView()
        .tabItem { Label("Schedule", systemImage: "calendar") }
    TasksView()
        .tabItem { Label("Tasks",    systemImage: "checkmark.circle.fill") }
    ShoppingView()
        .tabItem { Label("Shop",     systemImage: "cart.fill") }
    RewardsView()
        .tabItem { Label("Rewards",  systemImage: "star.fill") }
}
```

Child tab bar (3 tabs — when `authVM.currentProfile?.isChild == true`):
```swift
TabView {
    DashboardView()
        .tabItem { Label("Home",    systemImage: "house.fill") }
    TasksView()
        .tabItem { Label("Tasks",   systemImage: "checkmark.circle.fill") }
    RewardsView()
        .tabItem { Label("Rewards", systemImage: "star.fill") }
}
```

---

### Screen 05 — DashboardView
**File:** `Dashboard/DashboardView.swift`
**API call:** `GET /api/dashboard`

**Layout (ScrollView vertical, pull-to-refresh):**

**Header (dark navy):**
- Left: greeting text `"Good morning, Sarah ☀"` (time-aware: 5am–12pm morning / 12–5pm afternoon / 5pm+ evening) + date subtext `"Thursday, March 26"`
- Right: current user's avatar circle (28px, their color, initials) — tap → `SettingsView`

**Avatar filter row:**
- Horizontal scroll of `AvatarView` circles (26px each)
- Current user first, dark ring border (`#0C447C` 2px border for blue member)
- Gray "+" circle at end → opens invite member flow
- Tap a member → filter today's events to that member. Active = dark ring. Tap again = deactivate (show all).
- Only visible to parents

**AI card (parents only):**
```
Background: #FAEEDA, border: #F0C070, border-radius: 7
"⚡ AI — Conflict detected" label (8px bold #633806)
Body text (8px #633806, line-height 1.4)
"Resolve →" underlined tap target → navigates to action_url
```
If no AI card for today: green card with "Your family is all set for today ✓"

**"Today" section title**

**Event pills:**
- Background: member's color at 15% opacity
- Title: member's color, 9px bold
- Subtitle: time + "· MemberName", member's color, 8px, 0.8 opacity
- Conflict: `#FAEEDA` bg, `#F0C070` border, "⚠ " prefix on title, "· CONFLICT" in subtitle
- Tap → `EventDetailSheet`
- Max 5 shown. If more: "See all →" link to Schedule tab

**FAB (parents only):**
- Blue circle (`#185FA5`), "+" symbol, bottom-right, `shadow(radius: 4)`
- Tap → `FABBottomSheet` with 3 options:
  - "📅 Add event" → `AddEditEventView` sheet
  - "✅ Add task" → `AddEditTaskView` sheet
  - "🛒 Add shopping item" → `AddItemSheet` sheet

**Empty state (when `todaysEvents.isEmpty && pendingTasks.isEmpty`):**
Replace the event list with three dashed-border CTA cards:
```
Card 1: 📅 | "Add your first event"      | placeholder text | → (opens AddEditEventView)
Card 2: ✅ | "Assign a task"              | placeholder text | → (opens AddEditTaskView)
Card 3: 👥 | "Invite your partner"        | "Share the mental load" | → (opens invite flow)
```
Show welcome AI card: `"👋 Welcome to Doto"` — "Add your first event and task to get started."

**Parent vs Child differences:**
| Element | Parent | Child |
|---|---|---|
| AI card | Visible | Hidden |
| Today's events | All family | Only events where their ID is in `assignedTo` |
| FAB | Visible | Hidden |
| Avatar filter row | Visible | Hidden |
| Nav tabs | 5 tabs | 3 tabs |

---

### Screen 06 — ScheduleView
**File:** `Schedule/ScheduleView.swift`
**API call:** `GET /api/events?from=<weekStart>&to=<weekEnd>`

**Layout:**

**Header (dark navy):** "Schedule" + "+ Add" tap target (blue, 10px)

**Avatar member filter row:**
- Same component as Dashboard. Tap to filter events. Tap again to deactivate.

**WeekStripView:**
- Row 1: Day initials M T W T F S S (8px `#94A3B8`)
- Row 2: Date numbers (9px):
  - Today: `#185FA5` circle bg, white text, bold
  - Has events: `#DBEAFE` bg, `#0C447C` text
  - Default: `#64748B` text
- Tap a day → selects it, loads events below
- Swipe left/right on strip → previous/next week
- Arrow buttons `<` `>` in header area also navigate weeks

**Selected day label:** "Thursday, March 27" (9px bold `#1E293B`, shown above event list)

**Event list for selected day (vertical):**
- Each row is an event pill:
  - Title: member color, 9px bold
  - Subtitle: "3:30 PM · 45 min · Maple Clinic" (time + duration + location if set)
  - Normal bg: member color at 15% opacity
  - Conflict: `#FAEEDA` bg, `#F0C070` border, "⚠ " prefix, "· CONFLICT" in subtitle
- Tap normal event → `EventDetailSheet`
- Tap conflict event → `EventDetailSheet` showing "⚠ Conflicts with [name]" + "Resolve conflict →" button

**Conflict detection (client-side, runs after every fetch):**
```swift
func detectConflicts(_ events: [DotoEvent]) -> [DotoEvent] {
    return events.map { e1 in
        var e = e1
        e.isConflicting = events.contains { e2 in
            e1.id != e2.id &&
            e1.assignedTo.contains(where: e2.assignedTo.contains) &&
            e1.startAt < e2.endAt &&
            e1.endAt   > e2.startAt
        }
        return e
    }
}
```

**Empty state for selected day:** "No events this week" + "Tap + to add one"

---

### Screen 07 — AddEditEventView
**File:** `Schedule/AddEditEventView.swift`
**Presentation:** Bottom sheet modal (`.sheet`)
**API:** `POST /api/events` (create) or `PUT /api/events/:id` (edit)

**Header:** "Add event" / "Edit event" + "✕" close button (dark navy)

**Form fields:**

| Field | Input | Required | Notes |
|---|---|---|---|
| Title | Text field | ✅ | Max 100 chars, autofocus on open |
| Date | DatePicker `.date` | ✅ | Default: today or selected day from calendar |
| Start time | DatePicker `.time` | ✅ | 15-min increments |
| End time | DatePicker `.time` | ✅ | Must be after start. Inline error if not. |
| Repeat | Picker | ❌ | None (default) / Daily / Weekly / Monthly |
| Who is this for | Avatar multi-select | ✅ | At least 1 required. Unselected = 30% opacity. Selected = full opacity + dark ring border. |
| Location | Text field | ❌ | Free text, max 300 chars |
| Notes | TextEditor | ❌ | Max 500 chars |

Date and start/end time are displayed in a 2-column grid as in the wireframe.

**Edit mode only:** "Delete Event" destructive button at bottom → confirmation alert → `DELETE /api/events/:id`

---

### Screen 08 — TasksView
**File:** `Tasks/TasksView.swift`
**API calls:** `GET /api/tasks`, `PATCH /api/tasks/:id/complete`, `DELETE /api/tasks/:id`

**Header:** "Tasks" + "+ Add" tap target

**Layout — member cards (stacked vertically):**

One card per family member. Current user's card always first. Others alphabetical.
- Card bg: member color at 15% opacity
- Card border: member color at 40% opacity

**Card header:**
- Small avatar (20px) + member name (bold, member's dark text color) + "X / Y done" counter (member color, right-aligned)

**Progress bar:**
- Member color fill
- Value = tasks completed this week ÷ total tasks assigned this week (Mon 00:00 → Sun 23:59)
- Resets every Monday at 00:00

**Task rows inside card:**
- Checkbox (14×14, rounded square, `#CBD5E1` border when unchecked)
- Task title text
- Status badge (right-aligned)
- Incomplete tasks first (sorted by `dueAt` ASC), completed tasks at bottom (strikethrough gray)

**Badge styles:**
| Status | Condition | Badge | Text color |
|---|---|---|---|
| Overdue | `dueAt < today AND !isDone` | Red bg `#FCEBEB` | Red `#E24B4A` task title |
| Due today | `dueAt == today AND !isDone` | Amber bg `#FAEEDA` | Normal |
| Upcoming | `dueAt > today` | No badge | Normal |
| Done | `isDone` | Green "X pts" `#EAF3DE` | Strikethrough gray |

**Interactions:**
- Tap checkbox → optimistic UI (fill green + ✓) → `PATCH .../complete` → updates `profile.points` locally
- Swipe right on task → same as tap checkbox (complete)
- Swipe left on task → "Delete" revealed (parent only) → confirmation alert → `DELETE`
- Tap task title → `TaskDetailSheet` — shows title, notes, due date, points, assignee. Parent: Edit + Delete buttons. Child: read-only.

**Child view:** Only shows the card for the currently logged-in child (filtered by `assignedTo == currentProfile.id`). Parent card not shown.

**Pull-to-refresh** re-fetches.

**"+ Add" tap** → `AddEditTaskView` sheet

---

### Screen 09 — AddEditTaskView
**File:** `Tasks/AddEditTaskView.swift`
**Presentation:** Bottom sheet
**API:** `POST /api/tasks` or `PUT /api/tasks/:id`

**Form fields:**

| Field | Input | Required | Notes |
|---|---|---|---|
| Task name | Text field | ✅ | Max 100 chars, autofocus |
| Assign to | Avatar single-select | ✅ | One member only. Default: current user. |
| Due date | DatePicker `.date` | ✅ | Default: today |
| Points | Stepper / +/- buttons | ✅ | Range 1–100, default 10, step 5 |
| Notes | TextEditor | ❌ | Max 300 chars |
| Repeat | Picker | ❌ | None / Daily / Weekly |

---

### Screen 10 — ShoppingView
**File:** `Shopping/ShoppingView.swift`
**API calls:** `GET /api/shopping/lists`, `GET /api/shopping/lists/:id/items`, `PATCH .../check`, `DELETE .../items/:id`, `DELETE .../items/checked`

**This is a single screen — not two screens.** Lists are horizontal tabs at the top; items appear below.

**Header:** "Shopping" + "+ Add" tap target

**Horizontal list tab strip:**
- Pills (pill = `border-radius: 12px`):
  - Active: `#185FA5` bg, white text
  - Inactive: `#E2E8F0` bg, `#64748B` text
- Tabs: each list name + "| + New"
- Tap tab → switches active list, loads its items
- "+ New" tap → inline text input appears in the tab row → type name → submit → creates list → auto-selects it
- Long press on a list tab → "Delete list?" alert → `DELETE /api/shopping/lists/:id`
- "Groceries" is always auto-created on family setup (comes pre-populated from the server)

**Items area (below tab strip):**
- Items grouped by category
- Category header: emoji + category name (9px bold)
- Item row: checkbox | item name (+ " × quantity" if set) | added-by name (muted gray, right-aligned)
- Checked item: checkbox green filled, item text strikethrough gray
- Swipe left → delete item (no confirmation)
- Tap checkbox → **optimistic UI** toggle (update local state immediately) → `PATCH .../check` → revert on failure

**"Clear checked" button:**
- Appears at bottom of screen when `checkedCount > 0`
- Label: "Clear X checked items"
- Tap → `DELETE /api/shopping/lists/:id/items/checked`

**"+ Add" tap → `AddItemSheet`**

**Pull-to-refresh** re-fetches items for current list.

---

### Screen 11 — AddItemSheet
**File:** `Shopping/AddItemSheet.swift`
**Presentation:** Bottom sheet
**API:** `POST /api/shopping/lists/:id/items`

**Fields:**
- Item name (required, autofocused on appear)
- Quantity (optional free text, e.g. "× 2", "1 litre")
- Category (auto-detected from item name using keyword matching, shown as picker for manual override)

**Buttons:**
- "Add Item" — adds and dismisses
- "Add & Continue" — adds, clears name field, keeps sheet open for next item

---

### Screen 12 — RewardsView
**File:** `Rewards/RewardsView.swift`
**API calls:** `GET /api/rewards`, `PATCH .../request`, `PATCH .../approve`, `PATCH .../decline`, `DELETE /api/rewards/:id`

**Header:** "Rewards"

**Three sections (all visible to parents and children):**

**Section 1 — "This week's leaderboard 🏆"**
- White bordered card
- Rows: medal emoji (🥇🥈🥉 for top 3) + avatar (22px) + member name + weekly points (blue for 1st, gray for others)
- **Weekly points** = SUM of `task.points` WHERE `completedAt >= Monday 00:00` of current week. Computed from tasks, not from `profile.points`.
- All members shown, ranked DESC

**Section 2 — "[Child]'s goal" (one per child with active/pending rewards)**
- Amber card (`#FAEEDA` bg, `#FAC775` border)
- Title: emoji + reward name + "— X pts"
- Progress bar: member color fill, value = `profile.points (all-time) ÷ reward.pointsCost`
- "X / Y pts · Z to go" label
- When `profile.points >= reward.pointsCost`: green progress bar + "Claim! 🎉" button
- "Claim!" → `PATCH .../request` → sets `status = "pending_approval"` → button changes to "Pending..."
- Parents see approve/decline controls on pending_approval cards:
  - "Approve ✓" → `PATCH .../approve`
  - "Decline" → `PATCH .../decline` (reverts to `active`)

**Section 3 — "Streaks 🔥"**
- White bordered card
- Rows: avatar + member name + "🔥 X days" (amber `#BA7517` if streak > 0, gray if 0)
- Shows all members with assigned tasks (only children in practice)
- Streak = consecutive calendar days where ALL tasks assigned to that member were completed. Server-computed, stored in `profiles.streak`.

**"+ Set a goal" button** (shown below goals section — visible to both parents and children):
- Tap → inline form or sheet: reward title + points cost → `POST /api/rewards`

**Pull-to-refresh** re-fetches.

---

### Screen 13 — SettingsView
**File:** `Settings/SettingsView.swift`
**Route:** Tapping user avatar on Dashboard header. Parents only.

**Sections (SwiftUI `Form` / `List`):**

| Section | Items |
|---|---|
| Profile | Display name (editable), colour picker (8 preset swatches), change password |
| Family | Family name (editable), copy invite code button, manage members → `FamilyManageView` |
| Notifications | Toggle per type: task assigned / conflict / overdue / digest |
| Subscription | Current plan status, trial days remaining, "Manage billing" link |
| Danger zone | "Log out" + "Leave family" (keeps account) |

---

### Screen 14 — FamilyManageView
**File:** `Family/FamilyManageView.swift`
**API calls:** `GET /api/families/mine`, `POST /api/members`, `DELETE /api/members/:id`

**Layout:**
1. Family name + invite code with copy button
2. Members list — avatar + display name + role badge + all-time points
3. Swipe left on child rows → Delete (with confirmation)
4. "Add Child" button → modal: display name (required) + colour auto-assigned
5. "Log Out" destructive button → `authVM.logout()`

---

## 9. Shared Components

### `AvatarView.swift`
Circle with member's color as background, initials in white.

```swift
struct AvatarView: View {
    let name: String
    let color: String   // hex string
    var size: CGFloat = 26
    var isActive: Bool = false   // dark ring for selected state

    private var initials: String {
        name.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined().uppercased()
    }

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Color(hex: color))
            .clipShape(Circle())
            .overlay(
                Circle().stroke(
                    isActive ? Color(hex: color).opacity(0.8) : Color.clear,
                    lineWidth: 2
                )
            )
    }
}
```

### `MemberCardBackground.swift`
Used for task member cards.
```swift
struct MemberCardBackground: ViewModifier {
    let color: String
    func body(content: Content) -> some View {
        content
            .background(Color(hex: color).opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: color).opacity(0.4), lineWidth: 1)
            )
            .cornerRadius(8)
    }
}
```

### `Date+Formatting.swift`
```swift
extension Date {
    static let shortTimeFormatter: DateFormatter = {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none; return f
    }()
    static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()

    var shortTime: String { Date.shortTimeFormatter.string(from: self) }
    var shortDate: String { Date.shortDateFormatter.string(from: self) }

    var relativeDue: String {
        if Calendar.current.isDateInToday(self)     { return "Today" }
        if Calendar.current.isDateInTomorrow(self)  { return "Tomorrow" }
        if Calendar.current.isDateInYesterday(self) { return "Yesterday" }
        return shortDate
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: self)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var weekBounds: (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
        let end   = cal.date(byAdding: .day, value: 7, to: start)!
        return (start, end)
    }

    var isPast: Bool { self < Date() }
}
```

---

## 10. Standard ViewModel Pattern

Every ViewModel uses this exact structure:

```swift
@MainActor
class ExampleViewModel: ObservableObject {
    @Published var items: [SomeModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            items = try await APIClient.shared.get("/endpoint")
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

**Error alert** (add to root `View` of every screen):
```swift
.alert("Something went wrong",
    isPresented: Binding(
        get: { viewModel.errorMessage != nil },
        set: { if !$0 { viewModel.errorMessage = nil } }
    )
) {
    Button("OK", role: .cancel) {}
} message: {
    Text(viewModel.errorMessage ?? "")
}
```

---

## 11. Loading & Empty States

Every list view handles three states:

| State | Condition | Display |
|---|---|---|
| Loading | `items.isEmpty && isLoading` | `ProgressView()` centred |
| Empty | `items.isEmpty && !isLoading` | `EmptyStateView(message:icon:cta:)` centred |
| Populated | `!items.isEmpty` | Normal list with `.refreshable` |

Do not show a spinner during pull-to-refresh. The system `RefreshControl` handles that indicator.

```swift
var body: some View {
    Group {
        if items.isEmpty && isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if items.isEmpty {
            EmptyStateView(
                message: "No tasks yet",
                systemImage: "checkmark.circle",
                cta: "Add one"
            )
        } else {
            List(items) { item in
                // row
            }
            .refreshable { await viewModel.load() }
        }
    }
    .task { await viewModel.load() }
}
```

---

## 12. Onboarding Flow Summary

```
Register / Login
      │
      ▼
profile.familyId == nil?
      │ YES
      ▼
FamilySetupView  (step 2 of 3)
      │ on submit → POST /api/families → authVM.refreshProfile()
      ▼
NotificationsOnboardingView  (step 3 of 3)
      │ on either action → authVM.state = .ready
      ▼
MainTabView (Dashboard empty state on first open)

── Returning user ──
Login → profile.familyId set → authVM.state = .ready → MainTabView (Dashboard populated)
```
