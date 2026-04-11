# Doto — Bugs & Enhancements iOS Spec
**Version:** 1.0
**Scope:** All iOS changes for the bugs and enhancements list
**Files changed:** MainTabView, ShoppingView, AddItemSheet, TasksView,
RewardsView, FamilyManageView

---

## Overview

| # | Change | File(s) | API needed |
|---|---|---|---|
| 1 | Dashboard 5-day strip — today + 4 days | `DashboardViewModel` | Confirm existing |
| 2 | Tab label "Shop" → "Shopping Lists" | `MainTabView` | None |
| 3 | New list button label "New List" | `ShoppingView` | None |
| 4 | Add Item form — list picker dropdown | `AddItemSheet` | None (uses existing lists) |
| 5 | Shopping item edit + delete | `ShoppingView`, `EditItemSheet` | New PUT endpoint |
| 6 | Rewards — edit and delete goals (parent) | `RewardsView`, `GoalsSection` | Existing endpoints |
| 7 | Tasks — clear completed (parent only) | `TasksView` | New DELETE endpoint |
| 8 | FamilyManageView — Add Co-Parent button | `FamilyManageView` | None |
| 9 | AddItemSheet — buttons at bottom | `AddItemSheet` | None |

---

## 1. Dashboard 5-Day Strip — Today + 4 Days

**File:** `Dashboard/DashboardViewModel.swift`

The 5-day strip must always show **today as the first column**, not the start of
the calendar week. The strip shows: today, tomorrow, today+2, today+3, today+4.

```swift
// Dashboard/DashboardViewModel.swift — confirm selectedDayIndex default
// and that the days array is built from today, not week start

// In ParentDashboardResponse — the API returns days[0] = today.
// The iOS client must NOT re-sort or re-anchor these days.
// selectedDayIndex = 0 always means today on open.

@Published var selectedDayIndex = 0   // 0 = today, always
```

**FiveDayStripView** — confirm the first column label displays "Today" not the
day name when the date is today:

```swift
// Dashboard/Components/FiveDayStripView.swift
struct DayColumn: View {
    let day:        DashboardDay
    let isSelected: Bool
    let onTap:      () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                // Show "Today" label instead of day abbreviation for today
                Text(day.isToday ? "Today" : day.dayLabel)
                    .font(.system(size: 8, weight: isSelected ? .bold : .regular))
                    .foregroundColor(day.isToday ? Color.memberBlue : Color.textMuted)

                // Date circle
                ZStack {
                    Circle()
                        .fill(day.isToday ? Color.memberBlue : Color.clear)
                        .frame(width: 22, height: 22)
                    Text(day.dayNumber)
                        .font(.system(size: 11, weight: day.isToday ? .bold : .regular))
                        .foregroundColor(day.isToday ? .white : Color.textSecondary)
                }

                // Event dots
                HStack(spacing: 2) {
                    ForEach(day.memberColors.prefix(3), id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.selectedDayBg : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
```

---

## 2. Tab Label: "Shop" → "Shopping Lists"

**File:** `App/MainTabView.swift`

```swift
// BEFORE:
ShoppingView()
    .tabItem { Label("Shop", systemImage: "cart.fill") }

// AFTER:
ShoppingView()
    .tabItem { Label("Shopping Lists", systemImage: "cart.fill") }
```

Also update the screen header in `ShoppingView`:

```swift
// BEFORE:
DotoNavHeader(title: "Shopping")

// AFTER:
DotoNavHeader(title: "Shopping Lists")
```

---

## 3. New List Button: "+ New" → "New List"

**File:** `Shopping/ShoppingView.swift`

The tab strip currently shows a pill labelled `| + New` to create a new list.
Change the label to `+ New List` so it's clear what is being created.

```swift
// In ShoppingListTabStrip — the new list button:

// BEFORE:
Button("+ New") { ... }

// AFTER:
Button("+ New List") { ... }
    .font(.system(size: 12, weight: .medium))
    .foregroundColor(Color.memberBlue)
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .background(Color.selectedDayBg)
    .cornerRadius(14)
```

---

## 4. Add Item Form — List Picker

**Problem:** The "Add Item" button on the shopping screen (and the FAB on the
dashboard) opens `AddItemSheet` but it's not always clear which list the item
will be added to — especially when opened from the dashboard FAB where no list
is pre-selected context.

**Fix:** Add a list picker as the first field in `AddItemSheet`. Pre-select the
currently active list so it's frictionless for users already viewing a list,
but allow them to change it.

**File:** `Shopping/AddItemSheet.swift`

```swift
// Shopping/AddItemSheet.swift
struct AddItemSheet: View {
    // Pass the active list ID and all available lists
    let availableLists: [ShoppingList]
    let preselectedListId: String?

    @ObservedObject var vm: ShoppingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedListId: String = ""
    @State private var itemName:        String = ""
    @State private var quantity:        String = ""
    @State private var category:        ShoppingCategory = .other
    @State private var isSubmitting     = false

    var selectedList: ShoppingList? {
        availableLists.first { $0.id == selectedListId }
    }

    var body: some View {
        NavigationStack {
            Form {

                // ── List picker — shown first ──────────────────────────
                Section("Add to") {
                    if availableLists.isEmpty {
                        Text("No lists yet — create a list first")
                            .font(.system(size: 13))
                            .foregroundColor(Color.textMuted)
                    } else {
                        Picker("List", selection: $selectedListId) {
                            ForEach(availableLists) { list in
                                HStack(spacing: 8) {
                                    Text(list.storeTypeEmoji)
                                    Text(list.name)
                                }
                                .tag(list.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                // ── Item details ───────────────────────────────────────
                Section("Item") {
                    TextField("Item name", text: $itemName)
                        .autocorrectionDisabled()

                    TextField("Quantity (optional, e.g. × 2, 500g)", text: $quantity)
                        .font(.system(size: 14))

                    Picker("Category", selection: $category) {
                        ForEach(ShoppingCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    // Auto-detect category as user types
                    .onChange(of: itemName) { name in
                        category = ShoppingCategory.detect(from: name)
                    }
                }

            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
                    .foregroundColor(Color.textMuted)
            )

            // ── Buttons at the bottom ──────────────────────────────────
            VStack(spacing: 10) {
                // Add & Continue — adds item, keeps sheet open
                Button {
                    Task { await submitItem(andContinue: true) }
                } label: {
                    Text(isSubmitting ? "Adding..." : "Add & Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(itemName.trimmingCharacters(in: .whitespaces).isEmpty
                          || selectedListId.isEmpty
                          || isSubmitting)

                // Add Item — adds and dismisses
                Button {
                    Task { await submitItem(andContinue: false) }
                } label: {
                    Text(isSubmitting ? "Adding..." : "Add Item")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(itemName.trimmingCharacters(in: .whitespaces).isEmpty
                          || selectedListId.isEmpty
                          || isSubmitting)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .onAppear {
            // Pre-select the active list, fall back to first list
            selectedListId = preselectedListId ?? availableLists.first?.id ?? ""
            // Auto-detect category on name if pre-filled
        }
    }

    private func submitItem(andContinue: Bool) async {
        guard !selectedListId.isEmpty,
              !itemName.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let _: ShoppingItem = try await APIClient.shared.post(
                "/shopping/lists/\(selectedListId)/items",
                body: AddItemRequest(
                    name:     itemName.trimmingCharacters(in: .whitespaces),
                    quantity: quantity.isEmpty ? nil : quantity,
                    category: category.rawValue
                )
            )

            if andContinue {
                // Clear name and quantity, keep sheet open
                itemName = ""
                quantity = ""
                category = .other
            } else {
                dismiss()
            }

            // Notify the shopping view to refresh
            await vm.loadItems(for: selectedListId)
        } catch {
            // Show error — keep sheet open
        }
    }
}

struct AddItemRequest: Encodable {
    let name:     String
    let quantity: String?
    let category: String
}
```

**Calling AddItemSheet — pass lists and active list:**

```swift
// In ShoppingView:
.sheet(isPresented: $showAddItem) {
    AddItemSheet(
        availableLists:    vm.lists,
        preselectedListId: vm.activeListId,
        vm:                vm
    )
}

// In ParentDashboardView FAB:
// When "Add shopping item" is tapped from the FAB, open AddItemSheet
// with all lists loaded. If the user hasn't navigated to Shopping yet,
// load lists first:
.sheet(isPresented: $showAddShoppingItem) {
    AddItemSheet(
        availableLists:    dashboardVM.shoppingLists,  // pre-fetched with dashboard
        preselectedListId: nil,  // no pre-selection from dashboard
        vm:                shoppingVM
    )
}
```

---

## 5. Shopping Item — Edit and Delete

**Problem:** Currently only swipe-left-delete exists. No way to edit an item
after adding it (e.g. fix a typo in the name or change the quantity).

### 5.1 Edit — Long Press → Edit Sheet

Trigger edit by **long pressing** an item row. This opens `EditItemSheet`
(a simplified version of `AddItemSheet` without the list picker).

```swift
// Shopping/ShoppingView.swift — item row interaction:
ShoppingItemRow(item: item)
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
        // DELETE — existing, swipe from right
        Button(role: .destructive) {
            Task { await vm.deleteItem(item, from: activeListId) }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    .swipeActions(edge: .leading, allowsFullSwipe: false) {
        // EDIT — swipe from left reveals edit action
        Button {
            editingItem = item
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(Color.memberBlue)
    }
    .contextMenu {
        // Long press also shows a context menu
        Button {
            editingItem = item
        } label: {
            Label("Edit item", systemImage: "pencil")
        }
        Button(role: .destructive) {
            Task { await vm.deleteItem(item, from: activeListId) }
        } label: {
            Label("Delete item", systemImage: "trash")
        }
    }
```

### 5.2 EditItemSheet

```swift
// Shopping/EditItemSheet.swift
struct EditItemSheet: View {
    let item:       ShoppingItem
    let listId:     String
    @ObservedObject var vm: ShoppingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name:         String
    @State private var quantity:     String
    @State private var category:     ShoppingCategory
    @State private var isSubmitting  = false

    init(item: ShoppingItem, listId: String, vm: ShoppingViewModel) {
        self.item   = item
        self.listId = listId
        self.vm     = vm
        _name       = State(initialValue: item.name)
        _quantity   = State(initialValue: item.quantity ?? "")
        _category   = State(initialValue: ShoppingCategory(rawValue: item.category) ?? .other)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Item name", text: $name)
                        .autocorrectionDisabled()

                    TextField("Quantity (optional)", text: $quantity)

                    Picker("Category", selection: $category) {
                        ForEach(ShoppingCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
                    .foregroundColor(Color.textMuted)
            )

            // Buttons at the bottom
            VStack(spacing: 10) {
                Button {
                    Task { await saveEdit() }
                } label: {
                    Text(isSubmitting ? "Saving..." : "Save Changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func saveEdit() async {
        isSubmitting = true; defer { isSubmitting = false }
        do {
            struct EditBody: Encodable {
                let name: String; let quantity: String?; let category: String
            }
            let _: ShoppingItem = try await APIClient.shared.put(
                "/shopping/lists/\(listId)/items/\(item.id)",
                body: EditBody(
                    name:     name.trimmingCharacters(in: .whitespaces),
                    quantity: quantity.isEmpty ? nil : quantity,
                    category: category.rawValue
                )
            )
            await vm.loadItems(for: listId)
            dismiss()
        } catch {
            // show inline error
        }
    }
}
```

### 5.3 ShoppingViewModel additions

```swift
// Shopping/ShoppingViewModel.swift — add:

@Published var editingItem: ShoppingItem?

func deleteItem(_ item: ShoppingItem, from listId: String) async {
    // Optimistic: remove from local array immediately
    items.removeAll { $0.id == item.id }
    do {
        try await APIClient.shared.delete(
            "/shopping/lists/\(listId)/items/\(item.id)"
        )
    } catch {
        // Revert on failure
        await loadItems(for: listId)
        errorMessage = error.localizedDescription
    }
}
```

---

## 6. Rewards — Edit and Delete Goals (Parent Only)

**Problem:** There is no way for a parent to edit or delete a reward goal once
it's been created. Children who set a goal they later change their mind about
also have no recourse.

**Fix:** Long press or swipe on a goal card reveals Edit and Delete actions.
**Parent only.** Children can request/claim but cannot edit or delete goals.

### 6.1 GoalsSection — swipe + context menu

```swift
// In the goals section of RewardsView, wrap each reward card:
RewardGoalCard(reward: reward, member: member)
    .swipeActions(edge: .trailing) {
        // Delete (parent only)
        if currentProfile.isParent {
            Button(role: .destructive) {
                Task { await vm.deleteReward(reward) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    .swipeActions(edge: .leading) {
        // Edit (parent only)
        if currentProfile.isParent {
            Button {
                vm.editingReward = reward
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(Color.memberBlue)
        }
    }
    .contextMenu {
        if currentProfile.isParent {
            Button {
                vm.editingReward = reward
            } label: {
                Label("Edit goal", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Task { await vm.deleteReward(reward) }
            } label: {
                Label("Delete goal", systemImage: "trash")
            }
        }
    }
```

### 6.2 EditRewardSheet

```swift
// Rewards/EditRewardSheet.swift
struct EditRewardSheet: View {
    let reward: Reward
    @ObservedObject var vm: RewardsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title:        String
    @State private var emoji:        String
    @State private var pointsCost:   Int
    @State private var isSubmitting  = false

    init(reward: Reward, vm: RewardsViewModel) {
        self.reward = reward
        self.vm     = vm
        _title      = State(initialValue: reward.title)
        _emoji      = State(initialValue: reward.emoji ?? "")
        _pointsCost = State(initialValue: reward.pointsCost)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    HStack {
                        TextField("Emoji", text: $emoji)
                            .frame(width: 44)
                        TextField("Reward title", text: $title)
                    }
                    Stepper("Points: \(pointsCost)",
                            value: $pointsCost, in: 5...500, step: 5)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
                    .foregroundColor(Color.textMuted)
            )

            VStack(spacing: 10) {
                Button {
                    Task { await saveEdit() }
                } label: {
                    Text(isSubmitting ? "Saving..." : "Save Changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func saveEdit() async {
        isSubmitting = true; defer { isSubmitting = false }
        struct EditBody: Encodable {
            let title: String; let emoji: String?; let pointsCost: Int
        }
        do {
            let _: Reward = try await APIClient.shared.put(
                "/rewards/\(reward.id)",
                body: EditBody(
                    title:      title.trimmingCharacters(in: .whitespaces),
                    emoji:      emoji.isEmpty ? nil : emoji,
                    pointsCost: pointsCost
                )
            )
            await vm.loadRewards()
            dismiss()
        } catch {
            // show error
        }
    }
}
```

### 6.3 RewardsViewModel additions

```swift
// Rewards/RewardsViewModel.swift — add:
@Published var editingReward: Reward?
```

Add a `PUT /api/rewards/:id` endpoint call — this requires a new API endpoint.
Add to routes:
```
PUT  /api/rewards/:id   controllers.RewardController.update(id: String)
```

Body: `{ "title": "...", "emoji": "...", "pointsCost": 100 }`
Response: Updated reward object.
Only allowed when `status == "active"` — cannot edit a reward that is pending
approval or has been approved/redeemed.

---

## 7. Tasks — Clear Completed (Parent Only)

**Problem:** Completed tasks accumulate in the task list with no way to bulk
remove them. Parents need a way to clear the done pile.

**Fix:** A "Clear completed" action appears at the top-right of `TasksView`
header when any completed tasks exist. **Parent only.** Children cannot clear.

### 7.1 TasksView header update

```swift
// Tasks/TasksView.swift — updated header:
DotoNavHeader(
    title: "Tasks",
    trailing: {
        AnyView(HStack(spacing: 12) {
            // Clear completed — parent only, only when completed tasks exist
            if currentProfile.isParent && vm.hasCompletedTasks {
                Button {
                    showClearConfirm = true
                } label: {
                    Text("Clear done")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textMuted)
                }
            }
            // Existing + Add button
            Button("+ Add") { showAddTask = true }
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#60A5FA"))
        })
    }
)
.confirmationDialog(
    "Clear completed tasks?",
    isPresented: $showClearConfirm,
    titleVisibility: .visible
) {
    Button("Clear all completed", role: .destructive) {
        Task { await vm.clearCompleted() }
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This permanently removes all completed tasks for the whole family. This cannot be undone.")
}
```

### 7.2 TasksViewModel additions

```swift
// Tasks/TasksViewModel.swift — add:

var hasCompletedTasks: Bool {
    tasks.contains { $0.status == "done" }
}

func clearCompleted(memberId: String? = nil) async {
    do {
        struct ClearResponse: Decodable { let deletedCount: Int }
        var params: [String: String] = [:]
        if let id = memberId { params["memberId"] = id }
        let _: ClearResponse = try await APIClient.shared.delete(
            "/tasks/completed",
            params: params
        )
        // Remove completed tasks from local array
        tasks.removeAll { $0.status == "done" }
        if let id = memberId {
            // Only remove for that member
            tasks.removeAll { $0.status == "done" && $0.assignedTo == id }
        }
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

### 7.3 Per-member clear (optional — V1.5)

A parent can also clear just one member's completed tasks by long pressing the
member card header:

```swift
// Each member card header — long press:
MemberCardHeader(member: member, progress: progress)
    .contextMenu {
        if currentProfile.isParent {
            Button(role: .destructive) {
                Task { await vm.clearCompleted(memberId: member.id) }
            } label: {
                Label("Clear \(member.displayName)'s completed tasks",
                      systemImage: "trash")
            }
        }
    }
```

---

## 8. FamilyManageView — Add Co-Parent Button

**Problem:** The only way to invite a second parent is via the Settings screen
invite code. Parents managing the family members list have no direct path to
add another parent — the "Add Child" button is there but nothing for a co-parent.

**Fix:** Add an "Add a co-parent" button in `FamilyManageView` alongside
"Add a child". Tapping it shows the invite code with instructions in a modal.

### 8.1 FamilyManageView layout update

```swift
// Settings/Components/FamilyManageView.swift — updated sections:

List {
    // Members section (unchanged)
    Section("Members") {
        ForEach(vm.members) { member in
            MemberRowView(member: member)
        }
        .onDelete { ... }
    }

    // Action buttons section
    Section {
        // Add co-parent — NEW
        Button {
            showInviteParent = true
        } label: {
            Label("Add a co-parent", systemImage: "person.2.badge.plus")
                .foregroundColor(Color.memberBlue)
        }

        // Add child — existing
        Button {
            showAddChild = true
        } label: {
            Label("Add a child", systemImage: "person.badge.plus")
                .foregroundColor(Color.memberBlue)
        }
    }
}
.sheet(isPresented: $showInviteParent) {
    InviteCoParentSheet(inviteCode: vm.inviteCode, familyName: vm.familyName)
}
```

### 8.2 InviteCoParentSheet (New)

A simple bottom sheet showing the invite code, a brief explanation of how it
works, and a share button. No new API needed — uses the existing invite code.

```swift
// Settings/Components/InviteCoParentSheet.swift
struct InviteCoParentSheet: View {
    let inviteCode:  String
    let familyName:  String
    @Environment(\.dismiss) private var dismiss

    private var shareText: String {
        "Join our family on Doto! Download the app and enter code: \(inviteCode)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.cardBorder)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            // Title
            Text("Invite a co-parent")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            // Instructions blurb
            Text("Share this code with your partner. They'll open the Doto app, tap "Join a family" on the welcome screen, and enter the code below.")
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .lineSpacing(3)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 16)

            // Invite code display
            VStack(alignment: .leading, spacing: 6) {
                Text("Family invite code")
                    .font(.system(size: 11))
                    .foregroundColor(Color.textMuted)

                HStack {
                    Text(inviteCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.memberBlue)
                        .tracking(6)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = inviteCode
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(Color.memberBlue)
                    }
                }
            }
            .padding(16)
            .background(Color.selectedDayBg)
            .cornerRadius(12)
            .padding(.horizontal, 20)

            // How it works — short 3-step blurb
            VStack(alignment: .leading, spacing: 10) {
                Text("How it works")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.textSecondary)

                HowItWorksStep(number: "1", text: "They download Doto and open the app")
                HowItWorksStep(number: "2", text: "Tap "Join a family" on the welcome screen")
                HowItWorksStep(number: "3", text: "Enter the code above and create their account")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()

            // Share button
            ShareLink(item: shareText) {
                Label("Share invite via iMessage / WhatsApp",
                      systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .presentationDetents([.large])
    }
}

struct HowItWorksStep: View {
    let number: String
    let text:   String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.selectedDayBg)
                    .frame(width: 22, height: 22)
                Text(number)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.memberBlue)
            }
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
```

---

## 9. AddItemSheet — Buttons at Bottom (Not Top Right)

This is addressed in full in **Section 4** above. The `AddItemSheet` now uses
a `NavigationStack` with:
- `Cancel` as a leading nav bar button (left side of header)
- **No** trailing nav bar buttons (the old "Add" button top-right is removed)
- Two buttons at the **bottom** of the sheet in a `VStack`:
  1. "Add & Continue" — secondary style
  2. "Add Item" — primary style (blue)

Both buttons are disabled when the item name is empty or no list is selected.

The same bottom-button pattern applies to `EditItemSheet` (Section 5).

---

## 10. Summary of File Changes

| File | Change |
|---|---|
| `App/MainTabView.swift` | Tab label "Shop" → "Shopping Lists" |
| `Shopping/ShoppingView.swift` | Header title update, "+ New List" label, item swipe edit/delete, `editingItem` state |
| `Shopping/AddItemSheet.swift` | List picker as first field, buttons moved to bottom |
| `Shopping/EditItemSheet.swift` | New file |
| `Shopping/ShoppingViewModel.swift` | `deleteItem()`, `editingItem` published var |
| `Tasks/TasksView.swift` | "Clear done" header button (parent only), per-member context menu |
| `Tasks/TasksViewModel.swift` | `hasCompletedTasks` computed var, `clearCompleted()` |
| `Rewards/RewardsView.swift` | Swipe + context menu on goal cards (parent only) |
| `Rewards/EditRewardSheet.swift` | New file |
| `Rewards/RewardsViewModel.swift` | `editingReward` published var |
| `Settings/Components/FamilyManageView.swift` | "Add a co-parent" button |
| `Settings/Components/InviteCoParentSheet.swift` | New file |
| `Dashboard/Components/FiveDayStripView.swift` | "Today" label on today column |
