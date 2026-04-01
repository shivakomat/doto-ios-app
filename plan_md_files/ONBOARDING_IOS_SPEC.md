# Doto — iOS Spec: Onboarding
**Version:** 2.0
**Scope:** Auth screens, landing screen, family join flow, child self-registration
**Depends on:** Core IOS_SPEC.md — this document extends and overrides specific screens

---

## 1. Core Principles

- **No email field anywhere** in the app — not on register, not in settings, not in profile.
- **Username is the sole identifier** for all users — parents and children alike.
- **The family code is universal** — both parents and children use the same 6-char code.
- **Children self-register** — they choose their own username and password. No parent
  involvement in credential creation.
- **Code-first join flow** — users entering a family code see the family name before
  they create their account (Flow B).

---

## 2. Updated Data Models

### 2.1 Profile.swift

```swift
// Models/Profile.swift
struct Profile: Codable, Identifiable {
    let id: String
    let username: String           // sole login identifier — no email
    let displayName: String
    let role: String               // "parent" | "child"
    let color: String              // hex e.g. "#185FA5"
    var points: Int
    var streak: Int
    let familyId: String?          // null until family created or joined
    let isAuthAccount: Bool
    let createdAt: Date

    var isParent: Bool { role == "parent" }
    var isChild:  Bool { role == "child"  }
}
```

### 2.2 Request Bodies

```swift
// Auth/AuthRequests.swift

struct RegisterRequest: Encodable {
    let username: String
    let password: String
    let displayName: String
    let role: String               // "parent" | "child"
    let inviteCode: String?        // nil when creating a new family
}

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct CreateFamilyRequest: Encodable {
    let name: String
}

struct JoinFamilyRequest: Encodable {
    let inviteCode: String
    let role: String
}

struct ChangePasswordRequest: Encodable {
    let currentPassword: String
    let newPassword: String
}
```

### 2.3 FamilyPreview Model (New)

```swift
// Models/FamilyPreview.swift
// Returned by GET /api/families/preview/:code — no auth required
struct FamilyPreview: Decodable {
    let familyName: String
    let memberCount: Int
    let inviteCode: String
}
```

---

## 3. App States

```swift
// No change from core IOS_SPEC.md
enum AppState {
    case unauthenticated    // no JWT in Keychain
    case noFamily           // valid JWT, profile.familyId == nil
    case ready              // valid JWT + familyId set
}
```

---

## 4. Updated AuthViewModel

```swift
// Auth/AuthViewModel.swift
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
        guard KeychainHelper.loadToken() != nil else {
            state = .unauthenticated; return
        }
        do {
            let profile: Profile = try await APIClient.shared.get("/auth/me")
            currentProfile = profile
            state = profile.familyId == nil ? .noFamily : .ready
        } catch {
            KeychainHelper.deleteToken()
            state = .unauthenticated
        }
    }

    // Register with optional invite code — covers both paths
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
            // If inviteCode was provided, familyId will be set → go straight to ready
            // If no inviteCode, familyId is nil → go to FamilySetupView
            state = res.profile.familyId == nil ? .noFamily : .ready
        } catch APIError.conflict(_) {
            errorMessage = "That username is already taken. Try a different one."
        } catch APIError.notFound {
            errorMessage = "Invite code not found. Check the code and try again."
        } catch {
            errorMessage = error.localizedDescription
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

struct AuthResponse: Decodable { let token: String; let profile: Profile }
```

---

## 5. Navigation Structure (Unauthenticated)

When `authVM.state == .unauthenticated` the user sees the landing screen.
The landing screen is the entry point for all unauthenticated flows.

```
LandingView
    ├── "Sign in"           → SignInView
    ├── "Create a family"   → RegisterView(path: .createFamily)
    └── "Join a family"     → FamilyCodeEntryView
                                 └── FamilyPreviewView(code, preview)
                                         └── RegisterView(path: .joinFamily(code, preview))
```

The `RegisterView` is shared across both registration paths — it receives a `RegistrationPath`
enum that controls what it displays and what it submits.

---

## 6. Screen: LandingView (New)

**File:** `Auth/LandingView.swift`
**Route:** Shown when `authVM.state == .unauthenticated`

This is the first screen every user sees. It presents three clear actions with no
form fields — the form is on the next screen after the user has picked their path.

### Layout

```
┌──────────────────────────────────────────┐
│                                          │
│                                          │
│              Doto                        │  ← large bold, dark navy, centered
│         Family life. Done.               │  ← italic, gray, centered
│                                          │
│                                          │
│  [       Create a family         ]       │  ← primary blue button
│                                          │
│  [       Join a family           ]       │  ← secondary outlined button
│                                          │
│       Already have an account?           │  ← muted text
│            Sign in →                    │  ← blue link
│                                          │
│                                          │
└──────────────────────────────────────────┘
```

**Routing:**
- "Create a family" → `RegisterView(path: .createFamily)`
- "Join a family" → `FamilyCodeEntryView`
- "Sign in →" → `SignInView`

```swift
// Auth/LandingView.swift
struct LandingView: View {
    @State private var navigateTo: LandingDestination?

    enum LandingDestination {
        case createFamily, joinFamily, signIn
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 6) {
                    Text("Doto")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(Color.appNavy)
                    Text("Family life. Done.")
                        .font(.system(size: 16).italic())
                        .foregroundColor(Color.textSecondary)
                }

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    NavigationLink(destination: RegisterView(path: .createFamily)) {
                        Text("Create a family")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    NavigationLink(destination: FamilyCodeEntryView()) {
                        Text("Join a family")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textMuted)
                        NavigationLink(destination: SignInView()) {
                            Text("Sign in →")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.memberBlue)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
            .background(Color.white)
        }
    }
}
```

---

## 7. Screen: SignInView

**File:** `Auth/SignInView.swift`
**Route:** Tapped from LandingView "Sign in →" link

Simple screen. No path selection needed here — returning users always have a username.

### Layout

```
┌──────────────────────────────────────────┐
│  ←  Sign in                              │  ← nav back button
├──────────────────────────────────────────┤
│                                          │
│  Username                                │
│  [ sarah_smith                   ]       │
│                                          │
│  Password                                │
│  [ ••••••••••••              👁  ]       │
│                                          │
│  [errorMessage if any]                   │  ← red text
│                                          │
│  [         Sign in              ]        │
│                                          │
└──────────────────────────────────────────┘
```

**Field rules:**
- Username: `.autocapitalization(.never)`, `.autocorrectionDisabled()`
- Password: `SecureField` with show/hide eye toggle

**Error:** "Incorrect username or password." — never distinguish which was wrong.

```swift
// Auth/SignInView.swift
struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 16) {
            AuthTextField(
                label: "Username",
                text: $username,
                autocapitalization: .never
            )
            AuthSecureField(
                label: "Password",
                text: $password,
                showPassword: $showPassword
            )

            if let err = authVM.errorMessage {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#E24B4A"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(
                title: authVM.isLoading ? "Signing in..." : "Sign in",
                isLoading: authVM.isLoading
            ) {
                Task { await authVM.login(username: username, password: password) }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.large)
        Spacer()
    }
}
```

---

## 8. Screen: FamilyCodeEntryView (New)

**File:** `Auth/FamilyCodeEntryView.swift`
**Route:** Tapped from LandingView "Join a family"

The user enters the 6-char code. On submit the app calls
`GET /api/families/preview/:code` (no auth required). If valid, navigates to
`FamilyPreviewView` with the family name. If invalid, shows an inline error.

### Layout

```
┌──────────────────────────────────────────┐
│  ←  Join a family                        │
├──────────────────────────────────────────┤
│                                          │
│  Enter the invite code from your         │
│  family member's app.                    │
│                                          │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐   │  ← 6 char boxes
│  │ D │ │ O │ │ T │ │ 0 │ │ 4 │ │ X │   │
│  └───┘ └───┘ └───┘ └───┘ └───┘ └───┘   │
│                                          │
│  [error if code not found]               │  ← red text
│                                          │
│  [      Continue →       ]               │  ← disabled until 6 chars entered
│                                          │
└──────────────────────────────────────────┘
```

**Behaviour:**
- Input is auto-uppercased
- "Continue →" button is disabled until exactly 6 characters are entered
- On tap: calls `GET /api/families/preview/:code`
  - Success → push `FamilyPreviewView` onto the navigation stack
  - 404 → show "Code not found. Check it and try again." inline, clear the field

```swift
// Auth/FamilyCodeEntryView.swift
struct FamilyCodeEntryView: View {
    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var preview: FamilyPreview?
    @State private var navigateToPreview = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter the invite code from your family member's Doto app.")
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            CodeInputView(code: $code)

            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#E24B4A"))
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(
                title: isLoading ? "Checking..." : "Continue →",
                isLoading: isLoading
            ) {
                Task { await lookupCode() }
            }
            .disabled(code.count < 6 || isLoading)

            Spacer()
        }
        .padding(.horizontal, 28)
        .navigationTitle("Join a family")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $navigateToPreview) {
            if let preview {
                FamilyPreviewView(preview: preview)
            }
        }
    }

    private func lookupCode() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let result: FamilyPreview = try await APIClient.shared.get(
                "/families/preview/\(code.uppercased())"
            )
            preview = result
            navigateToPreview = true
        } catch APIError.notFound {
            errorMessage = "Code not found. Check it and try again."
            code = ""
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }
}
```

---

## 9. Screen: FamilyPreviewView (New)

**File:** `Auth/FamilyPreviewView.swift`
**Route:** Pushed from `FamilyCodeEntryView` after successful code lookup

Shows the family the user is about to join. Gives context before they commit to
creating an account. Role selection happens here.

### Layout

```
┌──────────────────────────────────────────┐
│  ←  You're joining...                    │
├──────────────────────────────────────────┤
│                                          │
│         The Smith Family                 │  ← large, bold, centered
│         2 members already               │  ← muted, centered
│                                          │
│  ────────────────────────────────────    │
│                                          │
│  I am a...                               │
│                                          │
│  ┌──────────────┐  ┌──────────────────┐  │
│  │  👨‍👩‍👧  Parent  │  │  👦  Child / Teen │  │  ← toggle cards
│  └──────────────┘  └──────────────────┘  │
│                                          │
│  [    Create my account →    ]           │
│                                          │
└──────────────────────────────────────────┘
```

**Role selection:**
- Two tappable cards: "Parent" and "Child / Teen"
- Selected card has a blue border and background tint
- Default: "Parent" selected
- No age enforcement — the user self-declares

**On "Create my account →":**
- Pushes `RegisterView(path: .joinFamily(code: preview.inviteCode, role: selectedRole))`

```swift
// Auth/FamilyPreviewView.swift
struct FamilyPreviewView: View {
    let preview: FamilyPreview
    @State private var selectedRole = "parent"

    var body: some View {
        VStack(spacing: 24) {
            // Family info
            VStack(spacing: 6) {
                Text(preview.familyName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text("\(preview.memberCount) member\(preview.memberCount == 1 ? "" : "s") already")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textMuted)
            }
            .padding(.top, 24)

            Divider()

            // Role selection
            VStack(alignment: .leading, spacing: 12) {
                Text("I am a...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.textPrimary)

                HStack(spacing: 12) {
                    RoleCard(
                        emoji: "👨‍👩‍👧",
                        label: "Parent",
                        isSelected: selectedRole == "parent"
                    ) { selectedRole = "parent" }

                    RoleCard(
                        emoji: "👦",
                        label: "Child / Teen",
                        isSelected: selectedRole == "child"
                    ) { selectedRole = "child" }
                }
            }

            NavigationLink(destination: RegisterView(
                path: .joinFamily(
                    inviteCode: preview.inviteCode,
                    role: selectedRole
                )
            )) {
                Text("Create my account →")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 24)
        .navigationTitle("You're joining...")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct RoleCard: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(emoji).font(.system(size: 28))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? Color.memberBlue : Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.selectedDayBg : Color.screenBg)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color.memberBlue : Color.cardBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cornerRadius(10)
        }
    }
}
```

---

## 10. Screen: RegisterView (Updated — Shared for Both Paths)

**File:** `Auth/RegisterView.swift`
**Route:** From LandingView "Create a family" OR from FamilyPreviewView "Create my account"

A single registration form handles both paths via `RegistrationPath`.

### RegistrationPath Enum

```swift
enum RegistrationPath {
    case createFamily
    // inviteCode and role come from FamilyPreviewView
    case joinFamily(inviteCode: String, role: String)
}
```

### Layout — Create Family Path

```
┌──────────────────────────────────────────┐
│  ←  Create your account                  │
├──────────────────────────────────────────┤
│                                          │
│  Display name                            │
│  [ Sarah                          ]      │
│                                          │
│  Username                                │
│  [ sarah_smith                    ]      │
│  Must be unique. Letters, numbers,       │
│  underscores only.                       │
│                                          │
│  Password                                │
│  [ ••••••••••••              👁  ]       │
│                                          │
│  Confirm password                        │
│  [ ••••••••••••              👁  ]       │
│                                          │
│  [error if any]                          │
│                                          │
│  [     Create my account →      ]        │
│                                          │
└──────────────────────────────────────────┘
```

### Layout — Join Family Path

Same form but with a confirmation banner at the top:

```
┌──────────────────────────────────────────┐
│  ←  Create your account                  │
├──────────────────────────────────────────┤
│  ┌────────────────────────────────────┐  │
│  │ ✓ Joining The Smith Family         │  │  ← green banner, locked in
│  │   as Child / Teen                  │  │
│  └────────────────────────────────────┘  │
│                                          │
│  [same fields as above]                  │
│                                          │
│  [     Create my account →      ]        │
│                                          │
└──────────────────────────────────────────┘
```

The banner is read-only — the code and role were confirmed on the previous screen.

### Field Rules

| Field | Type | Rules |
|---|---|---|
| Display name | TextField | 1–100 chars |
| Username | TextField | 3–50 chars, `^[a-z0-9_]+$` enforced client-side, `.autocapitalization(.never)` |
| Password | SecureField | Min 8 chars, show/hide toggle |
| Confirm password | SecureField | Must match password, validated on blur |

**Username validation (client-side, before submit):**
```swift
func isValidUsername(_ value: String) -> Bool {
    let regex = "^[a-z0-9_]{3,50}$"
    return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: value)
}
```

Show inline hint: "Letters, numbers, underscores only. No spaces." below the field.
Show inline error immediately if user types an invalid character (live validation).

### Error States

| Error | Display |
|---|---|
| Username taken | "That username is already taken. Try a different one." below button |
| Code not found (race condition) | "The invite code is no longer valid. Go back and try again." |
| Passwords don't match | "Passwords don't match." below confirm field, on blur |
| Password too short | "Password must be at least 8 characters." below password field |
| Generic | "Something went wrong. Please try again." |

### Code

```swift
// Auth/RegisterView.swift
struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    let path: RegistrationPath

    @State private var displayName  = ""
    @State private var username     = ""
    @State private var password     = ""
    @State private var confirmPw    = ""
    @State private var showPassword = false
    @State private var usernameError: String?

    private var confirmMismatch: Bool {
        !confirmPw.isEmpty && confirmPw != password
    }

    private var canSubmit: Bool {
        !displayName.isEmpty &&
        isValidUsername(username) &&
        password.count >= 8 &&
        !confirmMismatch &&
        !authVM.isLoading
    }

    // Banner info from joinFamily path
    private var familyBannerText: String? {
        if case .joinFamily(_, let role) = path {
            // FamilyPreviewView already stored preview — pass it through or look it up
            let roleLabel = role == "parent" ? "Parent" : "Child / Teen"
            return "Joining as \(roleLabel)"
        }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                // Join family confirmation banner
                if case .joinFamily(let code, let role) = path {
                    JoinConfirmationBanner(inviteCode: code, role: role)
                }

                // Display name
                AuthTextField(label: "Display name", text: $displayName)

                // Username
                VStack(alignment: .leading, spacing: 4) {
                    AuthTextField(
                        label: "Username",
                        text: Binding(
                            get: { username },
                            set: { username = $0.lowercased()
                                   usernameError = isValidUsername($0.lowercased()) || $0.isEmpty
                                       ? nil
                                       : "Letters, numbers, underscores only. No spaces." }
                        ),
                        autocapitalization: .never
                    )
                    if let err = usernameError {
                        Text(err)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#E24B4A"))
                    } else {
                        Text("Letters, numbers, underscores only.")
                            .font(.system(size: 11))
                            .foregroundColor(Color.textMuted)
                    }
                }

                // Password
                AuthSecureField(label: "Password (min. 8 characters)",
                                text: $password, showPassword: $showPassword)

                // Confirm password
                AuthSecureField(
                    label: "Confirm password",
                    text: $confirmPw,
                    showPassword: $showPassword,
                    error: confirmMismatch ? "Passwords don't match." : nil
                )

                // API error
                if let err = authVM.errorMessage {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#E24B4A"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Submit
                PrimaryButton(
                    title: authVM.isLoading ? "Creating account..." : "Create my account →",
                    isLoading: authVM.isLoading
                ) {
                    Task { await submit() }
                }
                .disabled(!canSubmit)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Create your account")
        .navigationBarTitleDisplayMode(.large)
    }

    private func submit() async {
        let (inviteCode, role): (String?, String) = {
            if case .joinFamily(let code, let r) = path { return (code, r) }
            return (nil, "parent")
        }()
        await authVM.register(
            username: username,
            password: password,
            displayName: displayName,
            role: role,
            inviteCode: inviteCode
        )
    }

    private func isValidUsername(_ value: String) -> Bool {
        let regex = "^[a-z0-9_]{3,50}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: value)
    }
}

// Banner shown on the join path confirming the family code + role
struct JoinConfirmationBanner: View {
    let inviteCode: String
    let role: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "#1D9E75"))
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text("Joining with code \(inviteCode)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#1D9E75"))
                Text("Role: \(role == "parent" ? "Parent" : "Child / Teen")")
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "#F0FDF4"))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#1D9E75"), lineWidth: 1))
        .cornerRadius(8)
    }
}
```

---

## 11. Screen: FamilySetupView (Simplified)

**File:** `Onboarding/FamilySetupView.swift`
**Route:** Shown when `authVM.state == .noFamily` (parent registered without a code)

This screen is **only reached by parents who created a new account without an invite code**.
Users who joined with a code never see this — they already have a `familyId`.

The "Add child" flow is removed from here. Children join by using a family code themselves.
Parents add the family name and get their invite code. That's it.

### Layout

```
┌──────────────────────────────────────────┐
│  Set up your family          Step 2 of 3 │  ← dark navy header
├──────────────────────────────────────────┤
│                                          │
│  Family name                             │
│  [ The Smith Family              ]       │
│                                          │
│  ──────────────────────────────────────  │
│                                          │
│  Your profile                            │
│  ┌──────────────────────────────────┐    │
│  │ SJ  Sarah (you)          Parent  │    │  ← creator's avatar, blue
│  └──────────────────────────────────┘    │
│                                          │
│  ──────────────────────────────────────  │
│                                          │
│  Invite your family                      │
│  Share this code with your partner       │
│  and children so they can join.          │
│                                          │
│  ┌──────────────────────────────┐        │
│  │  DOTO4X              [Copy] │        │  ← shows after family created
│  └──────────────────────────────┘        │
│                                          │
│  [  Share via iMessage / WhatsApp  ]     │  ← ShareLink
│                                          │
│  [          Continue →          ]        │
│                                          │
└──────────────────────────────────────────┘
```

**On "Continue →":**
1. `POST /api/families` with the family name
2. On success: `authVM.refreshProfile()` to get the updated `familyId`
3. Navigate to `NotificationsOnboardingView`

**The invite code** is shown as soon as the family is created (comes back in the
`POST /api/families` response). The parent can copy or share it immediately before
continuing to notifications.

**No "Add child" button.** Children join themselves using the code. Remove this from
the previous spec version.

```swift
// Family/FamilyViewModel.swift — simplified
@MainActor
class FamilyViewModel: ObservableObject {
    @Published var familyName     = ""
    @Published var createdFamily: Family?
    @Published var isLoading      = false
    @Published var errorMessage: String?

    func createFamily(authVM: AuthViewModel) async {
        guard !familyName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a family name."
            return
        }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let family: Family = try await APIClient.shared.post(
                "/families",
                body: CreateFamilyRequest(name: familyName)
            )
            createdFamily = family
            await authVM.refreshProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

---

## 12. Invite Code Display Component

Reusable across `FamilySetupView` and `SettingsView`:

```swift
// Shared/Components/InviteCodeView.swift
struct InviteCodeView: View {
    let code: String
    let familyName: String

    private var shareText: String {
        "Join \(familyName) on Doto! Enter this code in the app: \(code)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Family invite code")
                .font(.system(size: 12))
                .foregroundColor(Color.textMuted)

            HStack {
                Text(code)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.memberBlue)
                    .tracking(6)

                Spacer()

                Button {
                    UIPasteboard.general.string = code
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(Color.memberBlue)
                }
            }
            .padding(14)
            .background(Color.selectedDayBg)
            .cornerRadius(10)

            ShareLink(item: shareText) {
                Label("Share via iMessage / WhatsApp",
                      systemImage: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundColor(Color.memberBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.memberBlue, lineWidth: 1))
                    .cornerRadius(8)
            }
        }
    }
}
```

---

## 13. CodeInputView Component

Shared between `FamilyCodeEntryView` (unauthenticated) and any future code entry:

```swift
// Shared/Components/CodeInputView.swift
struct CodeInputView: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            TextField("", text: Binding(
                get: { code },
                set: { code = String($0.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6)) }
            ))
            .keyboardType(.default)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.characters)
            .focused($isFocused)
            .opacity(0.001)        // invisible but tappable for keyboard
            .frame(height: 52)

            HStack(spacing: 8) {
                ForEach(0..<6) { i in
                    let char = code.count > i
                        ? String(code[code.index(code.startIndex, offsetBy: i)])
                        : ""
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isFocused && code.count == i
                                ? Color.memberBlue : Color.cardBorder,
                            lineWidth: 1.5
                        )
                        .frame(width: 44, height: 52)
                        .overlay(
                            Text(char)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color.textPrimary)
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
        }
        .onAppear { isFocused = true }
    }
}
```

---

## 14. Complete Onboarding Flow Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PARENT — Creating a new family
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LandingView
  → "Create a family"
  → RegisterView(path: .createFamily)
      username + password + displayName
      role = "parent" (implicit, no inviteCode)
      POST /api/auth/register → familyId: null
  → authVM.state = .noFamily
  → FamilySetupView (Step 2 of 3)
      POST /api/families → gets inviteCode: "DOTO4X"
      Shows code to share with family members
  → NotificationsOnboardingView (Step 3 of 3)
  → authVM.state = .ready
  → DashboardView (empty state)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PARENT — Joining existing family with code
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LandingView
  → "Join a family"
  → FamilyCodeEntryView
      Enters: DOTO4X
      GET /api/families/preview/DOTO4X → "The Smith Family"
  → FamilyPreviewView
      Sees: "The Smith Family — 2 members"
      Selects role: Parent
  → RegisterView(path: .joinFamily(code: "DOTO4X", role: "parent"))
      username + password + displayName
      POST /api/auth/register (with inviteCode) → familyId: set
  → authVM.state = .ready
  → DashboardView (skips FamilySetup + Notifications)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CHILD — Joining family with code
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LandingView
  → "Join a family"
  → FamilyCodeEntryView
      Enters: DOTO4X
      GET /api/families/preview/DOTO4X → "The Smith Family"
  → FamilyPreviewView
      Sees: "The Smith Family — 2 members"
      Selects role: Child / Teen
  → RegisterView(path: .joinFamily(code: "DOTO4X", role: "child"))
      username + password + displayName
      POST /api/auth/register (with inviteCode + role: child) → familyId: set
  → authVM.state = .ready
  → DashboardView (3-tab restricted view)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RETURNING USER (any role)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LandingView
  → "Sign in →"
  → SignInView
      username + password
      POST /api/auth/login → familyId set
  → authVM.state = .ready
  → DashboardView
```
