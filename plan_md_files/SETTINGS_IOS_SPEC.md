# Doto — Settings iOS Spec
**Version:** 1.0
**Scope:** Parent SettingsView (full) + Child ChildProfileView (lightweight)
**Depends on:** Core IOS_SPEC.md, ONBOARDING_IOS_SPEC.md, REWARDS_IOS_SPEC.md,
SETTINGS_API_SPEC.md

---

## 1. Overview

There are two entirely separate settings experiences depending on role:

| Role | Entry point | Screen | Sections |
|---|---|---|---|
| Parent | Tap avatar in dashboard header | `SettingsView` | Profile, Family, Notifications, Rewards, Danger zone |
| Child | Tap avatar in dashboard header | `ChildProfileView` | Profile (read-only), Change password, Log out |

Children do not see or access `SettingsView`. Parents do not use `ChildProfileView`.
The correct screen is chosen in `DashboardView` based on `currentProfile.role`.

---

## 2. File Structure

```
Settings/
├── SettingsView.swift              ← Parent only
├── SettingsViewModel.swift         ← Parent only
├── ChildProfileView.swift          ← Child only
├── ChildProfileViewModel.swift     ← Child only
└── Components/
    ├── ColourPickerRow.swift        ← Shared colour swatch picker
    ├── FamilyManageView.swift       ← Existing — updated
    ├── NotificationToggles.swift    ← New
    └── DangerZoneSection.swift     ← New
```

---

## 3. Navigation Wiring

Update both dashboard headers to navigate to the correct screen:

```swift
// Dashboard/ParentDashboardView.swift
// Replace the stub:
onAvatarTap: { /* navigate to settings */ }
// With:
onAvatarTap: { showSettings = true }

// Add to ParentDashboardView:
.sheet(isPresented: $showSettings) {
    NavigationStack {
        SettingsView()
            .environmentObject(authVM)
    }
}

// Dashboard/ChildDashboardView.swift
// Replace the stub:
onAvatarTap: { /* navigate to profile settings */ }
// With:
onAvatarTap: { showProfile = true }

// Add to ChildDashboardView:
.sheet(isPresented: $showProfile) {
    NavigationStack {
        ChildProfileView()
            .environmentObject(authVM)
    }
}
```

---

## 4. SettingsViewModel (Parent)

```swift
// Settings/SettingsViewModel.swift
@MainActor
class SettingsViewModel: ObservableObject {

    // Profile
    @Published var displayName:   String = ""
    @Published var selectedColor: String = "#185FA5"

    // Family
    @Published var familyName:    String = ""
    @Published var inviteCode:    String = ""

    // Notifications
    @Published var notifications: NotificationPreferences = .defaults

    // State
    @Published var isSaving       = false
    @Published var errorMessage:  String?
    @Published var successMessage: String?
    @Published var showLeaveConfirm  = false
    @Published var showDeleteConfirm = false

    func load(profile: Profile, family: DashboardFamily?) async {
        displayName   = profile.displayName
        selectedColor = profile.color
        familyName    = family?.name ?? ""
        await loadInviteCode()
        await loadNotifications()
    }

    func loadInviteCode() async {
        do {
            struct InviteResponse: Decodable { let inviteCode: String; let familyName: String }
            let res: InviteResponse = try await APIClient.shared.get(
                "/families/mine/invite-code"
            )
            inviteCode = res.inviteCode
        } catch { /* silent — code shown if available */ }
    }

    func loadNotifications() async {
        do {
            struct Wrapper: Decodable { let preferences: NotificationPreferences }
            let res: Wrapper = try await APIClient.shared.get(
                "/profiles/me/notifications"
            )
            notifications = res.preferences
        } catch { /* use defaults if fetch fails */ }
    }

    func saveProfile() async {
        isSaving = true; errorMessage = nil; defer { isSaving = false }
        struct Body: Encodable { let displayName: String; let color: String }
        do {
            let _: Profile = try await APIClient.shared.patch(
                "/profiles/me",
                body: Body(displayName: displayName, color: selectedColor)
            )
            successMessage = "Profile updated"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveFamilyName() async {
        guard !familyName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSaving = true; defer { isSaving = false }
        struct Body: Encodable { let name: String }
        do {
            let _: EmptyResponse = try await APIClient.shared.patch(
                "/families/mine",
                body: Body(name: familyName)
            )
            successMessage = "Family name updated"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveNotifications() async {
        struct Wrapper: Encodable { let preferences: NotificationPreferences }
        do {
            let _: EmptyResponse = try await APIClient.shared.put(
                "/profiles/me/notifications",
                body: Wrapper(preferences: notifications)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveFamily(authVM: AuthViewModel) async {
        isSaving = true; defer { isSaving = false }
        do {
            struct LeaveResponse: Decodable { let leftFamily: Bool; let familyDeleted: Bool }
            let _: LeaveResponse = try await APIClient.shared.post(
                "/families/leave"
            )
            // Leave invalidates the JWT family context — log out and go to .noFamily state
            await authVM.logout()
        } catch APIError.conflict(let msg) {
            errorMessage = msg
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount(authVM: AuthViewModel) async {
        isSaving = true; defer { isSaving = false }
        do {
            let _: EmptyResponse = try await APIClient.shared.delete("/profiles/me")
            await authVM.logout()
        } catch APIError.conflict(let msg) {
            errorMessage = msg
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct NotificationPreferences: Codable {
    var taskAssigned:    Bool
    var taskOverdue:     Bool
    var taskCompleted:   Bool
    var scheduleConflict: Bool
    var rewardPending:   Bool
    var rewardApproved:  Bool
    var streakAtRisk:    Bool
    var bonusPoints:     Bool
    var weeklyDigest:    Bool

    static var defaults: NotificationPreferences {
        NotificationPreferences(
            taskAssigned:     true,
            taskOverdue:      true,
            taskCompleted:    true,
            scheduleConflict: true,
            rewardPending:    true,
            rewardApproved:   true,
            streakAtRisk:     true,
            bonusPoints:      true,
            weeklyDigest:     false
        )
    }

    enum CodingKeys: String, CodingKey {
        case taskAssigned     = "task_assigned"
        case taskOverdue      = "task_overdue"
        case taskCompleted    = "task_completed"
        case scheduleConflict = "schedule_conflict"
        case rewardPending    = "reward_pending"
        case rewardApproved   = "reward_approved"
        case streakAtRisk     = "streak_at_risk"
        case bonusPoints      = "bonus_points"
        case weeklyDigest     = "weekly_digest"
    }
}
```

---

## 5. SettingsView (Parent)

**File:** `Settings/SettingsView.swift`
**Route:** Sheet from parent avatar tap in dashboard header
**Style:** `NavigationStack` > `List` with `insetGrouped` style

### Layout

```
┌──────────────────────────────────┐
│  Settings                  [Done]│  ← nav title + Done button (dismisses sheet)
├──────────────────────────────────┤
│                                  │
│  PROFILE                         │
│  ┌──────────────────────────┐    │
│  │  Avatar     Sarah        │    │  ← large avatar left, name right
│  │  ( SJ )     @sarah_smith │    │  ← muted username below name
│  └──────────────────────────┘    │
│  Display name  [ Sarah       ]   │
│  Colour        🔵 🟢 🟡 🔴 🟣 🔴│  ← swatch row, current has checkmark
│  Change password             →   │
│                                  │
│  FAMILY                          │
│  Family name   [ The Smiths  ]   │
│  Invite code   DOTO4X  [Copy]    │
│  Share invite            [Share] │
│  Manage members              →   │
│                                  │
│  NOTIFICATIONS                   │
│  Task assigned           [  ●]   │  ← toggle on
│  Task overdue            [  ●]   │
│  Task completed          [  ●]   │
│  Schedule conflict       [  ●]   │
│  Reward approval         [  ●]   │
│  Streak at risk          [  ●]   │
│  Weekly digest           [○  ]   │  ← toggle off
│                                  │
│  REWARDS                         │
│  Manage reward catalog       →   │  ← navigates to RewardCatalogView
│                                  │
│  ACCOUNT                         │
│  Log out                         │  ← blue text
│  Leave family                    │  ← red text
│  Delete account                  │  ← red text
│                                  │
└──────────────────────────────────┘
```

```swift
// Settings/SettingsView.swift
struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showChangePassword = false
    @State private var showFamilyManage   = false
    @State private var showRewardCatalog  = false

    var body: some View {
        List {

            // ── PROFILE ──────────────────────────────────────────────
            Section("Profile") {

                // Avatar + name display row
                HStack(spacing: 14) {
                    AvatarView(
                        name:  vm.displayName,
                        color: vm.selectedColor,
                        size:  52
                    )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(vm.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        Text("@\(authVM.currentProfile?.username ?? "")")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textMuted)
                    }
                }
                .padding(.vertical, 4)

                // Display name field
                HStack {
                    Text("Display name")
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                    Spacer()
                    TextField("Your name", text: $vm.displayName)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color.textPrimary)
                        .onSubmit { Task { await vm.saveProfile() } }
                }

                // Colour picker
                ColourPickerRow(selectedColor: $vm.selectedColor) {
                    Task { await vm.saveProfile() }
                }

                // Change password
                Button {
                    showChangePassword = true
                } label: {
                    HStack {
                        Text("Change password")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textMuted)
                    }
                }
            }

            // ── FAMILY ───────────────────────────────────────────────
            Section("Family") {

                // Family name
                HStack {
                    Text("Family name")
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                    Spacer()
                    TextField("Family name", text: $vm.familyName)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color.textPrimary)
                        .onSubmit { Task { await vm.saveFamilyName() } }
                }

                // Invite code
                if !vm.inviteCode.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Invite code")
                                .font(.system(size: 11))
                                .foregroundColor(Color.textMuted)
                            Text(vm.inviteCode)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.memberBlue)
                                .tracking(4)
                        }
                        Spacer()
                        Button {
                            UIPasteboard.general.string = vm.inviteCode
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(Color.memberBlue)
                        }
                    }

                    // Share button
                    ShareLink(
                        item: "Join our family on Doto! Use code: \(vm.inviteCode)"
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                            Text("Share invite link")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(Color.memberBlue)
                    }
                }

                // Manage members
                Button {
                    showFamilyManage = true
                } label: {
                    HStack {
                        Text("Manage members")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textMuted)
                    }
                }
            }

            // ── NOTIFICATIONS ────────────────────────────────────────
            Section("Notifications") {
                NotificationToggles(prefs: $vm.notifications) {
                    Task { await vm.saveNotifications() }
                }
            }

            // ── REWARDS ──────────────────────────────────────────────
            Section("Rewards") {
                Button {
                    showRewardCatalog = true
                } label: {
                    HStack {
                        Text("Manage reward catalog")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textMuted)
                    }
                }
            }

            // ── ACCOUNT ──────────────────────────────────────────────
            Section("Account") {
                // Log out
                Button {
                    Task { await authVM.logout() }
                } label: {
                    Text("Log out")
                        .font(.system(size: 14))
                        .foregroundColor(Color.memberBlue)
                }

                // Leave family
                Button {
                    vm.showLeaveConfirm = true
                } label: {
                    Text("Leave family")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#E24B4A"))
                }

                // Delete account
                Button {
                    vm.showDeleteConfirm = true
                } label: {
                    Text("Delete account")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#E24B4A"))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .fontWeight(.semibold)
            }
        }

        // Error / success toast
        .overlay(alignment: .top) {
            if let msg = vm.successMessage {
                ToastView(message: msg, style: .success)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            vm.successMessage = nil
                        }
                    }
            }
            if let msg = vm.errorMessage {
                ToastView(message: msg, style: .error)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            vm.errorMessage = nil
                        }
                    }
            }
        }

        // Navigation destinations
        .navigationDestination(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .navigationDestination(isPresented: $showFamilyManage) {
            FamilyManageView()
        }
        .navigationDestination(isPresented: $showRewardCatalog) {
            RewardCatalogView()
        }

        // Leave family confirmation
        .confirmationDialog(
            "Leave family?",
            isPresented: $vm.showLeaveConfirm,
            titleVisibility: .visible
        ) {
            Button("Leave family", role: .destructive) {
                Task { await vm.leaveFamily(authVM: authVM) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your account will be kept but you will lose access to all family data. This cannot be undone.")
        }

        // Delete account confirmation
        .confirmationDialog(
            "Delete account?",
            isPresented: $vm.showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete my account", role: .destructive) {
                Task { await vm.deleteAccount(authVM: authVM) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your account and all your data will be permanently deleted. This cannot be undone.")
        }

        .task {
            await vm.load(
                profile: authVM.currentProfile!,
                family:  nil  // dashboard already has family — pass it through if needed
            )
        }
    }
}
```

---

## 6. Component: ColourPickerRow

```swift
// Settings/Components/ColourPickerRow.swift
struct ColourPickerRow: View {
    @Binding var selectedColor: String
    let onSelect: () -> Void

    private let palette = [
        "#185FA5", "#1D9E75", "#BA7517",
        "#993556", "#534AB7", "#E24B4A"
    ]

    var body: some View {
        HStack {
            Text("Colour")
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
            Spacer()
            HStack(spacing: 10) {
                ForEach(palette, id: \.self) { hex in
                    ZStack {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 26, height: 26)
                        if selectedColor == hex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .onTapGesture {
                        selectedColor = hex
                        onSelect()
                    }
                }
            }
        }
    }
}
```

---

## 7. Component: NotificationToggles

```swift
// Settings/Components/NotificationToggles.swift
struct NotificationToggles: View {
    @Binding var prefs: NotificationPreferences
    let onChange: () -> Void

    var body: some View {
        Group {
            ToggleRow(label: "Task assigned to me",    isOn: Binding(
                get: { prefs.taskAssigned },
                set: { prefs.taskAssigned = $0; onChange() }
            ))
            ToggleRow(label: "Overdue tasks",          isOn: Binding(
                get: { prefs.taskOverdue },
                set: { prefs.taskOverdue = $0; onChange() }
            ))
            ToggleRow(label: "Task completed (children)", isOn: Binding(
                get: { prefs.taskCompleted },
                set: { prefs.taskCompleted = $0; onChange() }
            ))
            ToggleRow(label: "Schedule conflict",      isOn: Binding(
                get: { prefs.scheduleConflict },
                set: { prefs.scheduleConflict = $0; onChange() }
            ))
            ToggleRow(label: "Reward approval needed", isOn: Binding(
                get: { prefs.rewardPending },
                set: { prefs.rewardPending = $0; onChange() }
            ))
            ToggleRow(label: "Streak at risk",         isOn: Binding(
                get: { prefs.streakAtRisk },
                set: { prefs.streakAtRisk = $0; onChange() }
            ))
            ToggleRow(label: "Weekly digest",          isOn: Binding(
                get: { prefs.weeklyDigest },
                set: { prefs.weeklyDigest = $0; onChange() }
            ))
        }
    }
}

struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(label, isOn: $isOn)
            .font(.system(size: 14))
            .foregroundColor(Color.textPrimary)
            .tint(Color.memberBlue)
    }
}
```

---

## 8. Screen: ChangePasswordView

**File:** `Settings/ChangePasswordView.swift`
**Route:** Pushed from SettingsView "Change password" row
**Reuse:** Same view used by children from `ChildProfileView`

```swift
// Settings/ChangePasswordView.swift
struct ChangePasswordView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentPw  = ""
    @State private var newPw      = ""
    @State private var confirmPw  = ""
    @State private var showPw     = false
    @State private var isLoading  = false
    @State private var errorMsg:  String?
    @State private var success    = false

    private var mismatch: Bool {
        !confirmPw.isEmpty && confirmPw != newPw
    }

    private var canSubmit: Bool {
        !currentPw.isEmpty && newPw.count >= 8 && !mismatch && !isLoading
    }

    var body: some View {
        List {
            Section {
                AuthSecureField(label: "Current password",
                                text: $currentPw, showPassword: $showPw)
                AuthSecureField(label: "New password (min. 8 characters)",
                                text: $newPw, showPassword: $showPw)
                AuthSecureField(label: "Confirm new password",
                                text: $confirmPw, showPassword: $showPw,
                                error: mismatch ? "Passwords don't match." : nil)
            }

            if let err = errorMsg {
                Section {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#E24B4A"))
                }
            }

            Section {
                Button {
                    Task {
                        isLoading = true; errorMsg = nil
                        let ok = await authVM.changePassword(
                            current: currentPw,
                            new:     newPw
                        )
                        isLoading = false
                        if ok {
                            success = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                dismiss()
                            }
                        } else {
                            errorMsg = "Current password is incorrect."
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else if success {
                            Label("Password updated!", systemImage: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#1D9E75"))
                        } else {
                            Text("Update password")
                                .fontWeight(.semibold)
                                .foregroundColor(canSubmit ? Color.memberBlue : Color.textMuted)
                        }
                        Spacer()
                    }
                }
                .disabled(!canSubmit)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Change password")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

---

## 9. Screen: FamilyManageView (Updated)

**File:** `Settings/Components/FamilyManageView.swift`
**Route:** Pushed from SettingsView "Manage members"
**Updates from core spec:** Now shows claim status per child (from CHILD_PROFILE_CLAIM_IOS_SPEC.md)

```swift
// Settings/Components/FamilyManageView.swift
struct FamilyManageView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = FamilyManageViewModel()
    @State private var showAddChild = false

    var body: some View {
        List {
            // Members section
            Section("Members") {
                ForEach(vm.members) { member in
                    MemberRowView(member: member)
                }
                .onDelete { indexSet in
                    // Only child rows are deletable — swipe left
                    vm.membersToDelete(at: indexSet)
                }
            }

            // Add child button
            Section {
                Button {
                    showAddChild = true
                } label: {
                    Label("Add a child", systemImage: "person.badge.plus")
                        .foregroundColor(Color.memberBlue)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Family members")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddChild) {
            AddChildSheet { displayName in
                Task { await vm.addChild(displayName: displayName) }
            }
        }
        .confirmationDialog(
            "Remove member?",
            isPresented: $vm.showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                Task { await vm.confirmDelete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \(vm.memberPendingDelete?.displayName ?? "this member") from the family. Their tasks and points history will be deleted.")
        }
        .task { await vm.load() }
    }
}

// Child row shows claim status (from CHILD_PROFILE_CLAIM_IOS_SPEC.md)
// MemberRowView is already defined there — reused here
```

---

## 10. Screen: ChildProfileView (Child)

**File:** `Settings/ChildProfileView.swift`
**Route:** Sheet from child avatar tap in `ChildDashboardHeader`
**Purpose:** The only settings surface for children. Change password + log out.

### Layout

```
┌──────────────────────────────────┐
│  My profile                [Done]│
├──────────────────────────────────┤
│                                  │
│           ( L )                  │  ← large avatar (60px), their colour
│            Liam                  │  ← display name, bold
│        @liam.doto4x              │  ← username, muted, smaller
│                                  │
│  ─── STATS ───────────────────   │
│  145 pts all-time                │
│  🔥 5 day streak                 │
│  🥇 1st this week                │
│                                  │
│  ─── ACCOUNT ─────────────────   │
│  Change password             →   │
│                                  │
│  Log out                         │  ← blue text
│                                  │
└──────────────────────────────────┘
```

```swift
// Settings/ChildProfileView.swift
struct ChildProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showChangePassword = false
    @State private var showLogoutConfirm  = false

    private var profile: Profile? { authVM.currentProfile }

    var body: some View {
        List {

            // ── PROFILE HEADER ────────────────────────────────────
            Section {
                VStack(spacing: 10) {
                    AvatarView(
                        name:  profile?.displayName ?? "",
                        color: profile?.color ?? "#BA7517",
                        size:  60
                    )
                    VStack(spacing: 3) {
                        Text(profile?.displayName ?? "")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        Text("@\(profile?.username ?? "")")
                            .font(.system(size: 13))
                            .foregroundColor(Color.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }

            // ── STATS ────────────────────────────────────────────
            Section("Stats") {
                HStack {
                    Text("All-time points")
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                    Spacer()
                    Text("\(profile?.pointsTotal ?? 0) pts")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.memberAmber)
                }
                HStack {
                    Text("Streak")
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                    Spacer()
                    Text(profile?.streakLabel ?? "—")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(
                            profile?.streakStatus == "none"
                                ? Color.textMuted
                                : Color.memberAmber
                        )
                }
            }

            // ── ACCOUNT ──────────────────────────────────────────
            Section("Account") {

                // Change password
                Button {
                    showChangePassword = true
                } label: {
                    HStack {
                        Text("Change password")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textMuted)
                    }
                }

                // Log out
                Button {
                    showLogoutConfirm = true
                } label: {
                    Text("Log out")
                        .font(.system(size: 14))
                        .foregroundColor(Color.memberBlue)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("My profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .fontWeight(.semibold)
            }
        }
        .navigationDestination(isPresented: $showChangePassword) {
            ChangePasswordView()
                .environmentObject(authVM)
        }
        .confirmationDialog(
            "Log out?",
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Log out", role: .destructive) {
                Task { await authVM.logout() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need your username and password to log back in.")
        }
    }
}
```

---

## 11. ToastView Component

Used in `SettingsView` to confirm saves without blocking the user:

```swift
// Shared/Components/ToastView.swift
enum ToastStyle { case success, error }

struct ToastView: View {
    let message: String
    let style:   ToastStyle

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: style == .success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(style == .success ? Color(hex: "#1D9E75") : Color(hex: "#E24B4A"))
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .padding(.top, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4), value: message)
    }
}
```

---

## 12. Updated Dashboard Header Wiring

Concrete replacements for the two comment stubs:

### ParentDashboardView

```swift
// Dashboard/ParentDashboardView.swift
@State private var showSettings = false

// In the header component call:
ParentDashboardHeader(
    profile:   data?.profile,
    members:   data?.family.members ?? [],
    onAvatarTap: { showSettings = true }    // ← replaces the comment stub
)

// Add to the view body:
.sheet(isPresented: $showSettings) {
    NavigationStack {
        SettingsView()
            .environmentObject(authVM)
    }
}
```

### ChildDashboardView

```swift
// Dashboard/ChildDashboardView.swift
@State private var showProfile = false

// In the header component call:
ChildDashboardHeader(
    profile:     data?.profile,
    onAvatarTap: { showProfile = true }     // ← replaces the comment stub
)

// Add to the view body:
.sheet(isPresented: $showProfile) {
    NavigationStack {
        ChildProfileView()
            .environmentObject(authVM)
    }
}
```

---

## 13. What Each Role Can Do — Full Summary

| Action | Parent | Child |
|---|---|---|
| View own username | ✅ (in Settings avatar row) | ✅ (in ChildProfileView) |
| Edit display name | ✅ | ❌ (parent sets it) |
| Change avatar colour | ✅ | ❌ |
| Change password | ✅ | ✅ |
| View own points + streak | ✅ (dashboard) | ✅ (ChildProfileView stats) |
| Edit family name | ✅ | ❌ |
| View/share invite code | ✅ | ❌ |
| Manage members | ✅ | ❌ |
| Manage reward catalog | ✅ | ❌ |
| Configure notifications | ✅ | ✅ (future — not in ChildProfileView for MVP) |
| Log out | ✅ | ✅ |
| Leave family | ✅ | ✅ (currently not in ChildProfileView — see note) |
| Delete account | ✅ | ❌ (for MVP — contact support instead) |

**Note on child leaving family:** A child being able to leave their own family is technically correct but potentially risky UX — a young child tapping "Leave family" by mistake would lose all their data. For MVP, omit "Leave family" from `ChildProfileView`. If a child needs to be removed, a parent does it from `FamilyManageView`. Add it to the child view in V1.5 once there's a robust confirmation flow.

---

## 14. Save Behaviour Rules

| Section | When saves |
|---|---|
| Display name | On `onSubmit` (keyboard return) or when user taps away from field |
| Colour | Immediately on swatch tap |
| Family name | On `onSubmit` |
| Notification toggles | Immediately on toggle tap (debounced 500ms to avoid API spam) |

All saves show a success toast briefly in the top of the screen. Errors replace the toast with a red message.
