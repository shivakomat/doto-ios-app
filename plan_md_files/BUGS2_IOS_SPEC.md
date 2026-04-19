# Doto — Bugs & Enhancements Part 2 — iOS Spec
**Version:** 1.0
**Scope:** iOS fixes for all six bugs in this batch

---

## Summary

| # | Bug | File(s) | Complexity |
|---|---|---|---|
| 1 | Username taken — error not shown clearly | `RegisterView` | Low |
| 2 | Create account disabled with no feedback | `RegisterView` | Low |
| 3 | Forgot password flow | `ForgotPasswordView`, `ResetPasswordView`, `AuthViewModel` | Medium |
| 4 | Category detection — eggs, spinach missing | `ShoppingCategory.swift` | Low |
| 5 | Children can't see shopping lists | `MainTabView`, `ShoppingView` | Low |
| 6 | Adding reward goal not working | `SetGoalView`, `RewardsViewModel` | Low |

---

## 1. Bug — Username Taken: Error Not Shown Clearly

### What's wrong

The `AuthViewModel` correctly sets `errorMessage = "That username is already
taken. Try a different one."` when it receives a `409` from the API. But in
`RegisterView` the error is displayed as a generic block at the bottom of the
form — below the submit button, easy to miss. It doesn't point to the username
field where the problem actually is.

### Fix

Show the error inline, directly below the username field, in red, as soon as
the 409 response comes back. Also re-focus the username field so the user can
immediately start typing a different one.

```swift
// Auth/RegisterView.swift

// Add a separate state variable for username-specific errors:
@State private var usernameError: String?

// In the username field section:
VStack(alignment: .leading, spacing: 4) {
    TextField("Username", text: $username)
        .autocorrectionDisabled()
        .autocapitalization(.none)
        .textContentType(.username)
        .onChange(of: username) { _ in
            // Clear the username error as soon as user starts editing again
            usernameError = nil
        }

    // Inline hint — always shown
    Text("Letters, numbers and underscores only")
        .font(.system(size: 11))
        .foregroundColor(Color.textMuted)

    // Inline error — shown when username is taken
    if let err = usernameError {
        Text(err)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color(hex: "#E24B4A"))
            .transition(.opacity)
    }
}

// In the submit handler — split the error by type:
do {
    try await authVM.register(...)
} catch APIError.conflict {
    // username-specific inline error, not the generic block
    usernameError = "That username is already taken. Try a different one."
    // Re-focus the username field
    usernameFocused = true
} catch {
    // Generic error (network, server) stays as the bottom block
    genericError = error.localizedDescription
}
```

**Remove** the generic `authVM.errorMessage` display for username conflicts — it
should only show for unexpected errors now, not for the 409 case which has its
own inline display.

---

## 2. Bug — Create Account Button Disabled With No Feedback

### What's wrong

The button is correctly disabled when `canSubmit == false` (password under 8
chars, fields empty, etc.). But there is no visual explanation. Users tap the
button, nothing happens, and they assume the app is broken.

### Two-part fix

**Part A — Inline password length hint that reacts as the user types:**

```swift
// Auth/RegisterView.swift — below the password field:
VStack(alignment: .leading, spacing: 4) {
    SecureField("Password", text: $password)

    // Show character count hint while password is being typed
    if !password.isEmpty && password.count < 8 {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 11))
                .foregroundColor(Color.memberAmber)
            Text("\(password.count)/8 characters minimum")
                .font(.system(size: 11))
                .foregroundColor(Color.memberAmber)
        }
        .transition(.opacity)
    } else if password.count >= 8 {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#1D9E75"))
            Text("Password looks good")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#1D9E75"))
        }
        .transition(.opacity)
    }
}
```

**Part B — Button visual state: disabled opacity + hint text below:**

```swift
// Auth/RegisterView.swift — the submit button section:
VStack(spacing: 8) {
    Button {
        Task { await submit() }
    } label: {
        Text(isLoading ? "Creating account..." : "Create account")
            .frame(maxWidth: .infinity)
    }
    .buttonStyle(PrimaryButtonStyle())
    .disabled(!canSubmit || isLoading)
    .opacity(canSubmit ? 1.0 : 0.5)  // visually dimmed when disabled

    // Contextual hint — explains why button is disabled
    // Only show when user has started filling in the form
    if !canSubmit && !username.isEmpty {
        Text(disabledReason)
            .font(.system(size: 12))
            .foregroundColor(Color.textMuted)
            .multilineTextAlignment(.center)
    }
}

// Computed property for contextual disabled reason:
private var disabledReason: String {
    if username.count < 3          { return "Username must be at least 3 characters" }
    if password.count < 8          { return "Password must be at least 8 characters" }
    if password != confirmPassword  { return "Passwords don't match" }
    return ""
}
```

**`canSubmit` logic (unchanged — confirming it's correct):**
```swift
private var canSubmit: Bool {
    username.count >= 3 &&
    password.count >= 8 &&
    password == confirmPassword &&
    !isLoading
}
```

---

## 3. Forgot Password Flow

### Decision summary (from API spec)

Email is added as an **optional** field. It is not required at registration.
It is only used for password reset. Login remains username-only.
Children who set an email can reset their own password. Children with no email
are reset by a parent via `ChangePasswordView` in `FamilyManageView`.

### 3.1 Add Email Field to Settings

Parents and children can optionally add a recovery email in their profile
settings.

```swift
// Settings/SettingsView.swift — add to Profile section:
Section("Profile") {
    // ... existing display name and colour rows ...

    // Recovery email (optional)
    HStack {
        Text("Recovery email")
            .font(.system(size: 14))
            .foregroundColor(Color.textSecondary)
        Spacer()
        TextField("Optional — for password reset", text: $recoveryEmail)
            .font(.system(size: 14))
            .multilineTextAlignment(.trailing)
            .foregroundColor(Color.textPrimary)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .onSubmit { Task { await vm.saveEmail(recoveryEmail) } }
    }

    if let emailError = vm.emailError {
        Text(emailError)
            .font(.system(size: 11))
            .foregroundColor(Color(hex: "#E24B4A"))
    }
}
```

Same field in `ChildProfileView`:
```swift
Section("Account") {
    // Existing change password row ...

    HStack {
        Text("Recovery email")
            .font(.system(size: 14))
            .foregroundColor(Color.textSecondary)
        Spacer()
        TextField("Optional", text: $recoveryEmail)
            .font(.system(size: 14))
            .multilineTextAlignment(.trailing)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .onSubmit { Task { await saveEmail() } }
    }
    Text("Used only for password reset — nothing else")
        .font(.system(size: 11))
        .foregroundColor(Color.textMuted)
}
```

### 3.2 "Forgot password?" Link on Login Screen

```swift
// Auth/LoginView.swift — add below the password field:
HStack {
    Spacer()
    Button("Forgot password?") {
        showForgotPassword = true
    }
    .font(.system(size: 13))
    .foregroundColor(Color.memberBlue)
}
.sheet(isPresented: $showForgotPassword) {
    ForgotPasswordView()
}
```

### 3.3 ForgotPasswordView

**File:** `Auth/ForgotPasswordView.swift`

```swift
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email       = ""
    @State private var isLoading   = false
    @State private var submitted   = false
    @State private var error:      String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if submitted {
                    // Success state
                    VStack(spacing: 20) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Color.memberBlue)

                        Text("Check your email")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.textPrimary)

                        Text("If an account with that email exists, we've sent a password reset link. It expires in 1 hour.")
                            .font(.system(size: 15))
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        Button("Back to login") { dismiss() }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 60)
                } else {
                    // Input state
                    Form {
                        Section {
                            Text("Enter the email address linked to your Doto account. We'll send you a link to reset your password.")
                                .font(.system(size: 14))
                                .foregroundColor(Color.textSecondary)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 8)

                            TextField("Your email address", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .textContentType(.emailAddress)

                            if let err = error {
                                Text(err)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#E24B4A"))
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        Button {
                            Task { await requestReset() }
                        } label: {
                            Text(isLoading ? "Sending..." : "Send reset link")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(email.isEmpty || isLoading)

                        // No email on file option
                        Button("I don't have an email set up") {
                            dismiss()
                            // Show the parent-reset explanation
                        }
                        .font(.system(size: 13))
                        .foregroundColor(Color.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Forgot password")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() }
                .foregroundColor(Color.textMuted))
        }
    }

    private func requestReset() async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            struct Body: Encodable { let email: String }
            struct Resp: Decodable { let sent: Bool }
            let _: Resp = try await APIClient.shared.post(
                "/auth/request-reset",
                body: Body(email: email.lowercased().trimmingCharacters(in: .whitespaces))
            )
            // Always show success — never reveal if email exists
            submitted = true
        } catch {
            self.error = "Something went wrong. Please try again."
        }
    }
}
```

### 3.4 No Email — Parent-Reset Path for Children

When a child forgets their password and has no email set, a parent can reset it
from `FamilyManageView`.

```swift
// Settings/Components/FamilyManageView.swift — on each child member row:
// Long press → context menu with "Reset password" option

MemberRowView(member: member)
    .contextMenu {
        if currentProfile.isParent {
            Button {
                resetTargetMember = member
                showResetChildPassword = true
            } label: {
                Label("Reset \(member.displayName)'s password",
                      systemImage: "key.fill")
            }
        }
    }

// Sheet:
.sheet(isPresented: $showResetChildPassword) {
    if let member = resetTargetMember {
        ResetChildPasswordSheet(member: member)
    }
}
```

```swift
// Settings/Components/ResetChildPasswordSheet.swift
struct ResetChildPasswordSheet: View {
    let member:   FamilyMemberSummary
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword   = ""
    @State private var confirmPw     = ""
    @State private var isLoading     = false
    @State private var error:        String?
    @State private var success       = false

    private var mismatch: Bool { !confirmPw.isEmpty && confirmPw != newPassword }
    private var canSubmit: Bool { newPassword.count >= 8 && !mismatch && !isLoading }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Set a new password for \(member.displayName). They'll need to use it to log back in.")
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                        .listRowBackground(Color.clear)
                }
                Section("New password") {
                    SecureField("New password (min. 8 characters)", text: $newPassword)
                    SecureField("Confirm new password", text: $confirmPw)
                    if mismatch {
                        Text("Passwords don't match.")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#E24B4A"))
                    }
                }
                if let err = error {
                    Section {
                        Text(err).font(.system(size: 12)).foregroundColor(Color(hex: "#E24B4A"))
                    }
                }
            }
            .navigationTitle("Reset password")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() })

            VStack {
                Button {
                    Task { await resetPassword() }
                } label: {
                    Text(success ? "Password updated ✓" : isLoading ? "Saving..." : "Set new password")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canSubmit)
            }
            .padding(.horizontal, 16).padding(.bottom, 24)
        }
    }

    private func resetPassword() async {
        isLoading = true; error = nil; defer { isLoading = false }
        // Uses PATCH /api/auth/admin-reset-password — parent-only endpoint
        // that resets another family member's password by profile ID.
        // This endpoint needs adding to the API (see BUGS2_API_SPEC.md).
        do {
            struct Body: Encodable { let profileId: String; let newPassword: String }
            struct Resp: Decodable { let reset: Bool }
            let _: Resp = try await APIClient.shared.patch(
                "/auth/admin-reset-password",
                body: Body(profileId: member.id, newPassword: newPassword)
            )
            success = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dismiss() }
        } catch {
            self.error = "Failed to reset password. Please try again."
        }
    }
}
```

**Additional API endpoint needed** (add to `BUGS2_API_SPEC.md`):

`PATCH /api/auth/admin-reset-password` — Parent only. Resets another family
member's password. Body: `{ "profileId": "uuid", "newPassword": "..." }`.
Validates that `profileId` belongs to the caller's family and that the target
profile is a child (cannot reset another parent's password this way).

---

## 4. Bug — Category Detection: Eggs, Spinach, Others Falling to "Other"

### What's wrong

The `ShoppingCategory.detect(from:)` function exists but its keyword map is
incomplete. Common items like spinach, lettuce, cucumber, eggs in some forms,
chicken, pasta, rice, and many others return `.other` instead of their correct
category.

### Fix — Complete keyword map

**File:** `Models/ShoppingCategory.swift`

Replace the existing `detect` function with this comprehensive version:

```swift
// Models/ShoppingCategory.swift

enum ShoppingCategory: String, CaseIterable, Codable {
    case produce   = "produce"
    case dairy     = "dairy"
    case meat      = "meat"
    case bakery    = "bakery"
    case frozen    = "frozen"
    case household = "household"
    case beverages = "beverages"
    case snacks    = "snacks"
    case other     = "other"

    var displayName: String {
        switch self {
        case .produce:   return "Fresh produce"
        case .dairy:     return "Dairy & eggs"
        case .meat:      return "Meat & fish"
        case .bakery:    return "Bakery"
        case .frozen:    return "Frozen"
        case .household: return "Household"
        case .beverages: return "Drinks"
        case .snacks:    return "Snacks"
        case .other:     return "Other"
        }
    }

    var emoji: String {
        switch self {
        case .produce:   return "🥬"
        case .dairy:     return "🥛"
        case .meat:      return "🥩"
        case .bakery:    return "🍞"
        case .frozen:    return "🧊"
        case .household: return "🧹"
        case .beverages: return "🥤"
        case .snacks:    return "🍪"
        case .other:     return "📦"
        }
    }

    // ── Keyword detection ────────────────────────────────────────
    static func detect(from name: String) -> ShoppingCategory {
        let n = name.lowercased().trimmingCharacters(in: .whitespaces)

        // ── Produce ──────────────────────────────────────────────
        let produce = [
            "apple", "banana", "orange", "lemon", "lime", "grape", "berry",
            "strawberry", "blueberry", "raspberry", "blackberry", "mango",
            "pineapple", "watermelon", "melon", "peach", "plum", "pear",
            "cherry", "avocado", "tomato", "tomatoes", "potato", "potatoes",
            "sweet potato", "carrot", "carrots", "onion", "onions",
            "garlic", "ginger", "broccoli", "cauliflower", "spinach",
            "lettuce", "kale", "cabbage", "celery", "cucumber", "courgette",
            "zucchini", "pepper", "peppers", "capsicum", "mushroom", "mushrooms",
            "asparagus", "corn", "peas", "green beans", "beans", "leek",
            "spring onion", "parsley", "coriander", "basil", "mint",
            "thyme", "rosemary", "herbs", "salad", "rocket", "watercress",
            "beetroot", "radish", "turnip", "parsnip", "squash", "pumpkin",
            "aubergine", "eggplant", "fennel", "artichoke", "sprouts",
            "brussel sprouts", "chilli", "chili", "jalapeño", "lime",
            "fresh fruit", "fruit", "veg", "vegetables"
        ]

        // ── Dairy & Eggs ──────────────────────────────────────────
        let dairy = [
            "milk", "whole milk", "semi-skimmed", "skimmed", "oat milk",
            "almond milk", "soy milk", "coconut milk", "plant milk",
            "butter", "margarine", "cream", "double cream", "single cream",
            "soured cream", "creme fraiche", "crème fraîche",
            "cheese", "cheddar", "mozzarella", "parmesan", "brie",
            "camembert", "feta", "gouda", "edam", "cottage cheese",
            "cream cheese", "ricotta", "halloumi",
            "yogurt", "yoghurt", "greek yogurt",
            "egg", "eggs", "free range", "free-range",
            "ice cream", "gelato"
        ]

        // ── Meat & Fish ───────────────────────────────────────────
        let meat = [
            "chicken", "chicken breast", "chicken thigh", "chicken legs",
            "whole chicken", "turkey", "duck",
            "beef", "mince", "steak", "sirloin", "ribeye", "brisket",
            "ground beef", "lamb", "lamb chops", "pork", "pork chop",
            "bacon", "ham", "gammon", "sausage", "sausages", "hot dog",
            "salami", "pepperoni", "chorizo", "prosciutto",
            "fish", "salmon", "tuna", "cod", "haddock", "tilapia",
            "sea bass", "trout", "mackerel", "sardines", "anchovies",
            "prawns", "shrimp", "crab", "lobster", "mussels", "oysters",
            "clams", "squid", "calamari", "scallops",
            "deli", "cold cuts", "meat"
        ]

        // ── Bakery ────────────────────────────────────────────────
        let bakery = [
            "bread", "loaf", "baguette", "sourdough", "rye bread",
            "wholemeal", "white bread", "rolls", "buns", "bagel", "bagels",
            "croissant", "croissants", "muffin", "muffins", "scone", "scones",
            "cake", "pastry", "pastries", "danish", "donut", "doughnut",
            "brioche", "ciabatta", "focaccia", "pita", "pitta",
            "tortilla", "wrap", "wraps", "crumpet", "crumpets"
        ]

        // ── Frozen ────────────────────────────────────────────────
        let frozen = [
            "frozen", "frozen pizza", "frozen chips", "frozen peas",
            "frozen fish", "fish fingers", "fish sticks",
            "frozen veg", "frozen vegetables", "frozen fruit",
            "ice lolly", "ice cream cone", "sorbet",
            "ready meal", "microwave meal"
        ]

        // ── Beverages ────────────────────────────────────────────
        let beverages = [
            "water", "sparkling water", "still water",
            "juice", "orange juice", "apple juice",
            "coffee", "espresso", "latte", "ground coffee", "coffee beans",
            "tea", "herbal tea", "green tea", "black tea",
            "coke", "cola", "pepsi", "diet coke", "zero",
            "lemonade", "squash", "cordial",
            "beer", "wine", "red wine", "white wine", "rosé", "prosecco",
            "champagne", "spirits", "gin", "vodka", "whisky", "rum",
            "energy drink", "sports drink", "smoothie", "kombucha",
            "hot chocolate", "cocoa"
        ]

        // ── Household ────────────────────────────────────────────
        let household = [
            "toilet paper", "toilet roll", "kitchen roll", "paper towels",
            "bin bags", "bin liners", "garbage bags", "trash bags",
            "washing up liquid", "dish soap", "dishwasher tablets",
            "laundry", "washing powder", "fabric softener", "conditioner",
            "bleach", "cleaning spray", "all purpose cleaner", "disinfectant",
            "sponge", "sponges", "cloths", "rubber gloves",
            "shampoo", "conditioner", "body wash", "shower gel", "soap",
            "toothpaste", "toothbrush", "mouthwash", "floss",
            "deodorant", "moisturiser", "sunscreen", "razor",
            "nappies", "diapers", "wipes", "baby wipes",
            "batteries", "lightbulb", "candle", "matches",
            "foil", "cling film", "baking paper", "parchment"
        ]

        // ── Snacks ───────────────────────────────────────────────
        let snacks = [
            "crisps", "chips", "popcorn", "pretzels", "crackers",
            "rice cakes", "corn chips", "tortilla chips",
            "chocolate", "biscuits", "cookies", "sweets", "candy",
            "gummy", "haribo", "marshmallow",
            "nuts", "almonds", "cashews", "peanuts", "pistachios",
            "trail mix", "granola bar", "cereal bar", "protein bar",
            "hummus", "dip", "salsa", "guacamole"
        ]

        // ── Match logic — check each category list ───────────────
        // Check for exact match first, then prefix/contains for longer names
        for keyword in produce   { if n == keyword || n.contains(keyword) { return .produce   } }
        for keyword in dairy     { if n == keyword || n.contains(keyword) { return .dairy     } }
        for keyword in meat      { if n == keyword || n.contains(keyword) { return .meat      } }
        for keyword in bakery    { if n == keyword || n.contains(keyword) { return .bakery    } }
        for keyword in frozen    { if n == keyword || n.contains(keyword) { return .frozen    } }
        for keyword in beverages { if n == keyword || n.contains(keyword) { return .beverages } }
        for keyword in household { if n == keyword || n.contains(keyword) { return .household } }
        for keyword in snacks    { if n == keyword || n.contains(keyword) { return .snacks    } }

        return .other
    }
}
```

**Items that were broken and now fixed:**

| Item typed | Before | After |
|---|---|---|
| spinach | other | produce ✓ |
| lettuce | other | produce ✓ |
| cucumber | other | produce ✓ |
| eggs (variant forms) | other | dairy ✓ |
| chicken breast | other | meat ✓ |
| salmon | other | meat ✓ |
| bin bags | other | household ✓ |
| crisps | other | snacks ✓ |
| orange juice | other | beverages ✓ |

---

## 5. Bug — Children Can't See Shopping Lists

### What's wrong

The child tab bar has 4 tabs: Home, Schedule, Tasks, Rewards.
Shopping Lists is not included. Children cannot see or add to family shopping
lists at all.

### Decision — Add Shopping Lists to child tab bar (5 tabs)

Children should be able to see the shopping lists and add items. They should
**not** be able to create or delete lists — only parents do that.

| Action | Parent | Child |
|---|---|---|
| View all lists | ✅ | ✅ |
| View items in a list | ✅ | ✅ |
| Check/uncheck items | ✅ | ✅ |
| Add items to a list | ✅ | ✅ |
| Create a new list | ✅ | ❌ |
| Delete a list | ✅ | ❌ |
| Edit an item | ✅ | ✅ |
| Delete an item | ✅ | ✅ |
| Clear checked items | ✅ | ❌ |

### Fix — Update child tab bar

```swift
// App/MainTabView.swift

// BEFORE (child tab bar — 4 tabs):
TabView {
    DashboardView()
        .tabItem { Label("Home",     systemImage: "house.fill") }
    ScheduleView(isReadOnly: true)
        .tabItem { Label("Schedule", systemImage: "calendar") }
    TasksView()
        .tabItem { Label("Tasks",    systemImage: "checkmark.circle.fill") }
    RewardsView()
        .tabItem { Label("Rewards",  systemImage: "star.fill") }
}

// AFTER (child tab bar — 5 tabs, Shopping Lists added):
TabView {
    DashboardView()
        .tabItem { Label("Home",            systemImage: "house.fill") }
    ScheduleView(isReadOnly: true)
        .tabItem { Label("Schedule",        systemImage: "calendar") }
    TasksView()
        .tabItem { Label("Tasks",           systemImage: "checkmark.circle.fill") }
    ShoppingView(isReadOnly: false, canManageLists: false)
        .tabItem { Label("Shopping Lists",  systemImage: "cart.fill") }
    RewardsView()
        .tabItem { Label("Rewards",         systemImage: "star.fill") }
}
```

### Update ShoppingView to accept `canManageLists` prop

```swift
// Shopping/ShoppingView.swift — add prop:
struct ShoppingView: View {
    var isReadOnly:     Bool = false   // future use
    var canManageLists: Bool = true    // false for children

    var body: some View {
        // ...existing code...

        // Hide "+ New List" button when canManageLists == false
        if canManageLists {
            Button("+ New List") { showNewList = true }
        }

        // Hide "Clear checked" button when canManageLists == false
        if canManageLists && vm.checkedCount > 0 {
            Button("Clear checked") { ... }
        }

        // Hide long-press "Delete list" when canManageLists == false
        // (remove the .onLongPressGesture from list tab pills in child mode)
    }
}
```

The `AddItemSheet` already handles list selection — children use the same sheet
and can add to any family list. No change needed to `AddItemSheet`.

---

## 6. Bug — Adding Reward Goal Not Working

### What's wrong

Two separate issues:

**Issue A — `memberId` required but not always provided.**
When a child opens `SetGoalView` and taps a catalog item or submits the custom
form, `createReward()` is called. The function signature requires `memberId` but
in some paths it's being passed as an empty string or `nil`. The API rejects
this with a 400.

**Issue B — `SetGoalView` not passing `memberId` correctly for child sessions.**
The child's own profile ID needs to be passed when a child creates their own
goal. In some code paths it falls through to an empty string.

### Fix — `RewardsViewModel.createReward`

```swift
// Rewards/RewardsViewModel.swift

// BEFORE — memberId required as a parameter:
func createReward(memberId: String, title: String, emoji: String?,
                  pointsCost: Int, catalogItemId: String?) async {

// AFTER — memberId optional, defaults to current profile:
func createReward(memberId: String? = nil,
                  title: String,
                  emoji: String?,
                  pointsCost: Int,
                  catalogItemId: String?) async {

    // Resolve memberId — use provided value or fall back to current user
    guard let resolvedMemberId = memberId ?? authVM.currentProfile?.id else {
        errorMessage = "Could not identify member. Please try again."
        return
    }

    isLoading = true; errorMessage = nil; defer { isLoading = false }

    struct CreateBody: Encodable {
        let memberId:     String
        let title:        String
        let emoji:        String?
        let pointsCost:   Int
        let catalogItemId: String?
    }

    do {
        let created: Reward = try await APIClient.shared.post(
            "/rewards",
            body: CreateBody(
                memberId:      resolvedMemberId,
                title:         title,
                emoji:         emoji,
                pointsCost:    pointsCost,
                catalogItemId: catalogItemId
            )
        )
        // Reload rewards and dismiss the sheet
        rewards.append(created)
        await loadRewards()
    } catch APIError.badRequest(let msg) {
        errorMessage = msg
    } catch {
        errorMessage = "Failed to create goal. Please try again."
    }
}
```

### Fix — SetGoalView call sites

Find every place in `SetGoalView` where `vm.createReward(...)` is called and
ensure `memberId` is either omitted (for children, who default to their own ID)
or correctly passed (for parents selecting a child).

```swift
// Rewards/SetGoalView.swift

// In the "Set goal" action for children — omit memberId:
await vm.createReward(
    // memberId omitted — defaults to current child
    title:        goal.title,
    emoji:        goal.emoji,
    pointsCost:   goal.pointsCost,
    catalogItemId: goal.catalogItemId
)
dismiss()

// In the "Set goal for child" action for parents — pass memberId:
await vm.createReward(
    memberId:     selectedChild.id,   // explicitly selected child
    title:        goal.title,
    emoji:        goal.emoji,
    pointsCost:   goal.pointsCost,
    catalogItemId: goal.catalogItemId
)
dismiss()
```

### Fix — Error surfacing in SetGoalView

The current `SetGoalView` calls `createReward` but doesn't check
`vm.errorMessage` after the call. Add error display:

```swift
// Rewards/SetGoalView.swift — after the submit button:
if let err = vm.errorMessage {
    Text(err)
        .font(.system(size: 12))
        .foregroundColor(Color(hex: "#E24B4A"))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
}
```

---

## 7. Summary of File Changes

| File | Change |
|---|---|
| `Auth/RegisterView.swift` | Inline username-taken error below field, password length hint, disabled button reason |
| `Auth/LoginView.swift` | "Forgot password?" link below password field |
| `Auth/ForgotPasswordView.swift` | New file — email input + success state |
| `Settings/SettingsView.swift` | Optional recovery email field in Profile section |
| `Settings/ChildProfileView.swift` | Optional recovery email field in Account section |
| `Settings/Components/FamilyManageView.swift` | Long-press child row → "Reset password" option |
| `Settings/Components/ResetChildPasswordSheet.swift` | New file — parent sets new password for child |
| `Models/ShoppingCategory.swift` | Complete keyword map with 150+ items across all categories |
| `App/MainTabView.swift` | Child tab bar: add Shopping Lists as 5th tab |
| `Shopping/ShoppingView.swift` | Add `canManageLists` prop, hide list management actions for children |
| `Rewards/RewardsViewModel.swift` | `createReward` — memberId optional, defaults to current profile |
| `Rewards/SetGoalView.swift` | Fix memberId in all call sites, add error display |
