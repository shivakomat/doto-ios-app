# Doto — iOS Spec: Child Profile Claim
**Version:** 1.0
**Feature:** Linking a child's self-registered account to an existing parent-created profile
**Scope:** SwiftUI iOS
**Depends on:** ONBOARDING_IOS_SPEC.md — specifically FamilyPreviewView and RegisterView

---

## 1. Overview

When a parent adds a child profile from `FamilyManageView`, that child appears in the
family but has no login credentials. When the child later wants to use the app on their
own device, they enter the family code and see a new screen — `ClaimProfileView` —
which shows any existing unclaimed child profiles in the family.

The child taps their name, sets a username and password, and their new account is
linked to the existing profile. All previous points, streak, task history, and reward
goals are preserved.

If the child is not listed (either because no placeholder was created, or they want a
fresh account), they tap "I'm not listed" and go through the standard `RegisterView`.

---

## 2. Where This Fits in the Flow

This screen inserts between `FamilyPreviewView` and `RegisterView` — but only when:
1. The user selected role: **Child / Teen** on `FamilyPreviewView`
2. `unclaimedChildren` from the preview response is **not empty**

```
FamilyCodeEntryView
      ↓
FamilyPreviewView
      ↓ (role = child AND unclaimedChildren not empty)
ClaimProfileView       ← NEW
      ↓ (tapped their name)          ↓ (tapped "I'm not listed")
ClaimRegisterView      ← NEW         RegisterView (existing)
```

If `unclaimedChildren` is empty, or the user selected role: Parent, `ClaimProfileView`
is skipped entirely.

---

## 3. Updated Data Models

### 3.1 UnclaimedChild Model (New)

```swift
// Models/UnclaimedChild.swift
struct UnclaimedChild: Decodable, Identifiable {
    let id: String
    let displayName: String
    let color: String
}
```

### 3.2 FamilyPreview Model (Updated)

```swift
// Models/FamilyPreview.swift
struct FamilyPreview: Decodable {
    let familyName: String
    let memberCount: Int
    let inviteCode: String
    let unclaimedChildren: [UnclaimedChild]   // empty array if none, never nil
}
```

### 3.3 ClaimProfileRequest (New)

```swift
// Auth/AuthRequests.swift — add this
struct ClaimProfileRequest: Encodable {
    let profileId: String
    let inviteCode: String
    let username: String
    let password: String
}
```

---

## 4. Updated AuthViewModel

Add the `claimProfile` method alongside the existing `register` and `login` methods:

```swift
// Auth/AuthViewModel.swift — add this method
func claimProfile(
    profileId: String,
    inviteCode: String,
    username: String,
    password: String
) async {
    isLoading = true; errorMessage = nil; defer { isLoading = false }
    do {
        let res: AuthResponse = try await APIClient.shared.post(
            "/auth/claim-profile",
            body: ClaimProfileRequest(
                profileId:  profileId,
                inviteCode: inviteCode,
                username:   username,
                password:   password
            )
        )
        KeychainHelper.saveToken(res.token)
        currentProfile = res.profile
        // familyId is always set on a claimed profile
        state = .ready
    } catch APIError.conflict(let msg) {
        if msg.contains("username") {
            errorMessage = "That username is already taken. Try a different one."
        } else {
            errorMessage = "This profile has already been claimed."
        }
    } catch APIError.notFound {
        errorMessage = "Something went wrong. Go back and try again."
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

---

## 5. Screen: ClaimProfileView (New)

**File:** `Auth/ClaimProfileView.swift`
**Route:** Pushed from `FamilyPreviewView` when role is child and unclaimed children exist

### Purpose

Shows the list of unclaimed child profiles in the family. The child taps their name
to begin claiming it, or taps "I'm not listed" to create a fresh account instead.

### Layout

```
┌──────────────────────────────────────────┐
│  ←  Are you already here?                │
├──────────────────────────────────────────┤
│                                          │
│  A parent may have already added you     │
│  to this family. Tap your name if you    │
│  see it below.                           │
│                                          │
│  ┌──────────────────────────────────┐    │
│  │  L   Liam              Select → │    │  ← member colour, avatar, name
│  └──────────────────────────────────┘    │
│                                          │
│  ┌──────────────────────────────────┐    │
│  │  E   Emma              Select → │    │
│  └──────────────────────────────────┘    │
│                                          │
│  ─────────────────────────────────────   │
│                                          │
│  I'm not listed —                        │
│  create a new account instead  →         │  ← plain link, no button style
│                                          │
└──────────────────────────────────────────┘
```

**Behaviour:**
- Each row shows the child's avatar (their existing family colour + initials) and
  display name
- Tap a row → navigates to `ClaimRegisterView` with that child's profile pre-selected
- "I'm not listed" → navigates to `RegisterView(path: .joinFamily(...))` as normal

```swift
// Auth/ClaimProfileView.swift
struct ClaimProfileView: View {
    let preview: FamilyPreview

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Instruction text
            Text("A parent may have already added you to this family. Tap your name if you see it.")
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // Unclaimed child rows
            VStack(spacing: 1) {
                ForEach(preview.unclaimedChildren) { child in
                    NavigationLink(
                        destination: ClaimRegisterView(
                            child: child,
                            preview: preview
                        )
                    ) {
                        UnclaimedChildRow(child: child)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 24)

            // Divider
            Divider()
                .padding(.vertical, 20)
                .padding(.horizontal, 24)

            // Not listed option
            NavigationLink(
                destination: RegisterView(
                    path: .joinFamily(
                        inviteCode: preview.inviteCode,
                        role: "child"
                    )
                )
            ) {
                HStack {
                    Text("I'm not listed — create a new account instead")
                        .font(.system(size: 14))
                        .foregroundColor(Color.memberBlue)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color.memberBlue)
                }
                .padding(.horizontal, 24)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .navigationTitle("Are you already here?")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.screenBg)
    }
}

// Row component for each unclaimed child
struct UnclaimedChildRow: View {
    let child: UnclaimedChild

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(
                name: child.displayName,
                color: child.color,
                size: 38
            )

            Text(child.displayName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.textPrimary)

            Spacer()

            Text("Select")
                .font(.system(size: 13))
                .foregroundColor(Color.memberBlue)
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundColor(Color.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
    }
}
```

---

## 6. Screen: ClaimRegisterView (New)

**File:** `Auth/ClaimRegisterView.swift`
**Route:** Pushed from `ClaimProfileView` when a child taps their name

### Purpose

A simplified registration form for claiming an existing profile. The child's display
name is already set — they only need to choose a username and password.
Shows the child's existing points and streak to reinforce that their history will
be preserved.

### Layout

```
┌──────────────────────────────────────────┐
│  ←  Set up your login                    │
├──────────────────────────────────────────┤
│                                          │
│  ┌──────────────────────────────────┐    │
│  │  L   Liam                        │    │  ← their avatar at full size
│  │       145 pts  ·  5 day streak   │    │  ← existing stats shown
│  └──────────────────────────────────┘    │
│                                          │
│  These will be yours once you log in.    │  ← reassurance copy
│                                          │
│  ─────────────────────────────────────   │
│                                          │
│  Choose a username                       │
│  [ liam_smith                    ]       │
│  Letters, numbers, underscores only.     │
│                                          │
│  Choose a password                       │
│  [ ••••••••••••              👁  ]       │
│                                          │
│  Confirm password                        │
│  [ ••••••••••••              👁  ]       │
│                                          │
│  [error if any]                          │
│                                          │
│  [      This is me — let me in!  ]       │
│                                          │
└──────────────────────────────────────────┘
```

**Key detail:** The points and streak are shown before the form. This is intentional —
it gives the child confidence that their existing progress will not be lost, which is
the main anxiety this flow needs to resolve.

**The display name is not editable here.** It was set by the parent when the profile
was created. If the child wants to change it, they can do so from profile settings
after logging in.

```swift
// Auth/ClaimRegisterView.swift
struct ClaimRegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    let child: UnclaimedChild
    let preview: FamilyPreview

    @State private var username      = ""
    @State private var password      = ""
    @State private var confirmPw     = ""
    @State private var showPassword  = false
    @State private var usernameError: String?

    private var confirmMismatch: Bool {
        !confirmPw.isEmpty && confirmPw != password
    }

    private var canSubmit: Bool {
        isValidUsername(username) &&
        password.count >= 8 &&
        !confirmMismatch &&
        !authVM.isLoading
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Profile preview card
                ProfilePreviewCard(child: child)

                Text("These points and streak will be yours once you log in.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Divider()

                // Username field
                VStack(alignment: .leading, spacing: 4) {
                    AuthTextField(
                        label: "Choose a username",
                        text: Binding(
                            get: { username },
                            set: {
                                username = $0.lowercased()
                                usernameError = isValidUsername($0.lowercased()) || $0.isEmpty
                                    ? nil
                                    : "Letters, numbers, underscores only. No spaces."
                            }
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

                // Password fields
                AuthSecureField(
                    label: "Choose a password",
                    text: $password,
                    showPassword: $showPassword
                )
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
                    title: authVM.isLoading ? "Setting up your account..." : "This is me — let me in!",
                    isLoading: authVM.isLoading
                ) {
                    Task {
                        await authVM.claimProfile(
                            profileId:  child.id,
                            inviteCode: preview.inviteCode,
                            username:   username,
                            password:   password
                        )
                    }
                }
                .disabled(!canSubmit)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .navigationTitle("Set up your login")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.screenBg)
    }

    private func isValidUsername(_ value: String) -> Bool {
        let regex = "^[a-z0-9_]{3,50}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: value)
    }
}

// Card showing the child's existing stats before they commit
struct ProfilePreviewCard: View {
    let child: UnclaimedChild

    var body: some View {
        HStack(spacing: 16) {
            AvatarView(name: child.displayName, color: child.color, size: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(child.displayName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.textPrimary)

                // Note: points and streak come from the UnclaimedChild model
                // We need to extend that model to include them for this card
                // See section 7 below
                HStack(spacing: 12) {
                    Label("\(child.points) pts", systemImage: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.memberAmber)
                    Label("\(child.streak) day streak", systemImage: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.memberAmber)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color(hex: child.color).opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: child.color).opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}
```

---

## 7. Extended UnclaimedChild Model

The `ProfilePreviewCard` in `ClaimRegisterView` shows existing points and streak.
These need to come from the API. Update the model and API to include them:

```swift
// Models/UnclaimedChild.swift — updated
struct UnclaimedChild: Decodable, Identifiable {
    let id: String
    let displayName: String
    let color: String
    let points: Int      // show in ClaimRegisterView to reassure the child
    let streak: Int      // show in ClaimRegisterView to reassure the child
}
```

**Corresponding API update** (`GET /api/families/preview/:code`):
```json
"unclaimedChildren": [
  {
    "id": "uuid-liam",
    "displayName": "Liam",
    "color": "#BA7517",
    "points": 145,
    "streak": 5
  }
]
```

Update `CHILD_PROFILE_CLAIM_API_SPEC.md` section 4.1 accordingly.

---

## 8. Updated FamilyPreviewView

`FamilyPreviewView` needs to conditionally route to `ClaimProfileView` instead of
`RegisterView` when the conditions are met:

```swift
// Auth/FamilyPreviewView.swift — update the navigation button

// Determine next destination based on role + unclaimed children
private var nextDestination: AnyView {
    if selectedRole == "child" && !preview.unclaimedChildren.isEmpty {
        return AnyView(ClaimProfileView(preview: preview))
    } else {
        return AnyView(RegisterView(
            path: .joinFamily(inviteCode: preview.inviteCode, role: selectedRole)
        ))
    }
}

// Replace the existing NavigationLink with:
NavigationLink(destination: nextDestination) {
    Text("Create my account →")
        .frame(maxWidth: .infinity)
}
.buttonStyle(PrimaryButtonStyle())
```

---

## 9. Updated FamilyManageView (Parent Side)

Parents should see whether each child has claimed their profile or not. Update
the child rows in `FamilyManageView` to show claim status:

### Member Row — Unclaimed Child
```
┌──────────────────────────────────────────┐
│  E   Emma                 No account yet │
│       30 pts                             │
└──────────────────────────────────────────┘
```

- "No account yet" label in muted gray
- No username shown

### Member Row — Claimed Child
```
┌──────────────────────────────────────────┐
│  L   Liam                  @liam_smith   │
│       145 pts  ·  5 day streak           │
└──────────────────────────────────────────┘
```

- `@username` shown in muted text on the right
- Points + streak shown

```swift
// Family/MemberRowView.swift
struct MemberRowView: View {
    let member: Profile

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: member.displayName, color: member.color, size: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(member.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.textPrimary)

                if member.isChild {
                    HStack(spacing: 8) {
                        Text("\(member.points) pts")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textMuted)
                        if member.streak > 0 {
                            Text("· \(member.streak) day streak 🔥")
                                .font(.system(size: 12))
                                .foregroundColor(Color.memberAmber)
                        }
                    }
                }
            }

            Spacer()

            // Claim status / role badge
            if member.isChild {
                if member.isAuthAccount, let username = member.username {
                    Text("@\(username)")
                        .font(.system(size: 11))
                        .foregroundColor(Color.textMuted)
                } else {
                    Text("No account yet")
                        .font(.system(size: 11))
                        .foregroundColor(Color.textMuted)
                        .italic()
                }
            } else {
                Text("Parent")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.memberBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.selectedDayBg)
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 8)
    }
}
```

---

## 10. Complete Claim Flow — Step by Step

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CHILD — Claiming an existing profile
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LandingView
  → "Join a family"

FamilyCodeEntryView
  Enters: DOTO4X
  GET /api/families/preview/DOTO4X
  Returns: "The Smith Family", unclaimedChildren: [Liam, Emma]

FamilyPreviewView
  Sees: "The Smith Family — 3 members"
  Selects role: Child / Teen
  Taps: "Create my account →"
  → unclaimedChildren not empty + role = child
  → routes to ClaimProfileView

ClaimProfileView
  Sees: Liam (145 pts), Emma (30 pts)
  Taps: Liam

ClaimRegisterView
  Sees: Liam's profile card — 145 pts, 5 day streak
  Enters: username "liam_smith", password, confirm password
  Taps: "This is me — let me in!"
  POST /api/auth/claim-profile {
    profileId: "uuid-liam",
    inviteCode: "DOTO4X",
    username: "liam_smith",
    password: "..."
  }
  → 201 Created, token + profile (points: 145, streak: 5)
  → KeychainHelper.saveToken(token)
  → authVM.state = .ready

DashboardView (3-tab restricted, child view)
  Points: 145 — everything preserved ✓


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CHILD — Not in the list (no placeholder exists)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(Same as above until ClaimProfileView)

ClaimProfileView
  Taps: "I'm not listed — create a new account instead"
  → RegisterView(path: .joinFamily(code: "DOTO4X", role: "child"))

RegisterView
  Enters: displayName, username, password, confirm
  POST /api/auth/register { inviteCode, role: "child" }
  → 201 Created, fresh profile (points: 0)
  → authVM.state = .ready

DashboardView (3-tab restricted, child view, fresh start)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EDGE CASE — Child profile already claimed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ClaimRegisterView submits
  POST /api/auth/claim-profile
  → 409 conflict "This profile already has an account"
  → errorMessage shown: "This profile has already been claimed."
  → User goes back to ClaimProfileView
  → Remaining unclaimed children shown
  → Or taps "I'm not listed" for fresh account
```

---

## 11. Edge Cases to Handle

| Scenario | Behaviour |
|---|---|
| All children in the family have already been claimed | `unclaimedChildren` is empty → `ClaimProfileView` is skipped, goes straight to `RegisterView` |
| Parent role selected on `FamilyPreviewView` | `ClaimProfileView` skipped regardless — parents always go to `RegisterView` |
| Child taps back from `ClaimRegisterView` | Returns to `ClaimProfileView`, other children still shown |
| Username already taken on `ClaimRegisterView` | "That username is already taken. Try a different one." — inline error, form stays open |
| Network error on claim | Generic error shown, user can retry without losing their form input |
| Child profile has 0 points and 0 streak | `ProfilePreviewCard` still shows "0 pts · 0 day streak" — no hiding, it's honest |
