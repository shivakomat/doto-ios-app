# Doto — Rewards iOS Spec (Improved)
**Version:** 1.0
**Scope:** All rewards screens and components — parent view, child view, points history,
bonus points, set goal, reward catalog, milestone celebration, streak grace, family goal
**Replaces:** Screen 12 (RewardsView) in core IOS_SPEC.md
**Depends on:** Core IOS_SPEC.md for shared components, REWARDS_API_SPEC.md

---

## 1. Summary of New Screens and Components

| Screen / Component | Status | File |
|---|---|---|
| RewardsView (parent) | Updated | `Rewards/RewardsView.swift` |
| RewardsView (child) | Updated | `Rewards/RewardsView.swift` |
| PointsHistoryView | New | `Rewards/PointsHistoryView.swift` |
| BonusPointsSheet | New | `Rewards/BonusPointsSheet.swift` |
| SetGoalView | Updated | `Rewards/SetGoalView.swift` |
| RewardCatalogView | New | `Rewards/RewardCatalogView.swift` |
| MilestoneCelebrationView | New | `Rewards/MilestoneCelebrationView.swift` |
| FamilyGoalCard | New (V2) | `Rewards/FamilyGoalCard.swift` |
| StreakView | Updated (in RewardsView) | inline component |

---

## 2. Updated Data Models

### 2.1 Profile.swift — Updated Points Fields

```swift
// Models/Profile.swift
struct Profile: Codable, Identifiable {
    let id: String
    let username: String
    let displayName: String
    let role: String
    let color: String
    var pointsTotal:   Int        // all-time earned, never decreases
    var pointsBalance: Int        // spendable, decremented on redeem
    var streak:        Int        // current consecutive days
    var streakStatus:  String     // "active" | "grace" | "none"
    var streakGraceUsed: Bool
    let familyId: String?
    let isAuthAccount: Bool
    let createdAt: Date

    var isParent: Bool { role == "parent" }
    var isChild:  Bool { role == "child"  }

    // Streak display helpers
    var streakEmoji: String {
        switch streakStatus {
        case "active": return "🔥"
        case "grace":  return "🔸"
        default:       return ""
        }
    }

    var streakLabel: String {
        switch streakStatus {
        case "active": return "\(streak) days"
        case "grace":  return "\(streak) grace"
        default:       return "—"
        }
    }
}
```

### 2.2 Reward.swift — Updated

```swift
// Models/Reward.swift
struct Reward: Codable, Identifiable {
    let id: String
    let familyId: String
    let memberId: String
    var title: String
    var emoji: String?
    var pointsCost: Int
    var catalogItemId: String?
    var status: String     // "active"|"pending_approval"|"approved"|"redeemed"
    var requestedAt: Date?
    var approvedBy:  String?
    var approvedAt:  Date?
    let createdAt: Date
    let updatedAt: Date

    var statusLabel: String {
        switch status {
        case "active":           return "Active"
        case "pending_approval": return "Pending ⏳"
        case "approved":         return "Approved ✓"
        case "redeemed":         return "Redeemed 🎉"
        default:                 return status
        }
    }

    var titleWithEmoji: String {
        if let e = emoji { return "\(e) \(title)" }
        return title
    }
}
```

### 2.3 New Models

```swift
// Models/RewardsModels.swift

// Leaderboard
struct LeaderboardEntry: Decodable, Identifiable {
    var id: String { memberId }
    let memberId:     String
    let displayName:  String
    let color:        String
    let role:         String
    let weeklyPoints: Int
    let totalPoints:  Int
    let rank:         Int
}

struct Leaderboard: Decodable {
    let weekStart: Date
    let weekEnd:   Date
    let entries:   [LeaderboardEntry]
}

// Points history
struct PointsHistoryEntry: Decodable, Identifiable {
    let id:          String
    let eventType:   String    // "task"|"bonus"|"redeem"|"milestone"
    let amount:      Int       // positive for earn, negative for spend
    let note:        String?
    let referenceId: String?
    let createdAt:   Date

    var isEarning: Bool { amount > 0 }

    var icon: String {
        switch eventType {
        case "task":      return "checkmark.circle.fill"
        case "bonus":     return "gift.fill"
        case "redeem":    return "ticket.fill"
        case "milestone": return "medal.fill"
        default:          return "circle.fill"
        }
    }

    var iconColor: String {
        switch eventType {
        case "task":      return "#1D9E75"
        case "bonus":     return "#185FA5"
        case "redeem":    return "#E24B4A"
        case "milestone": return "#185FA5"
        default:          return "#94A3B8"
        }
    }
}

struct PointsHistoryResponse: Decodable {
    let memberId:      String
    let displayName:   String
    let pointsTotal:   Int
    let pointsBalance: Int
    let entries:       [PointsHistoryEntry]
    let hasMore:       Bool
    let nextBefore:    Date?
}

// Reward catalog
struct RewardCatalogItem: Codable, Identifiable {
    let id:         String
    let familyId:   String
    var title:      String
    var emoji:      String?
    var pointsCost: Int
    let createdBy:  String
    let createdAt:  Date

    var titleWithEmoji: String {
        if let e = emoji { return "\(e) \(title)" }
        return title
    }
}

// Bonus points
struct BonusPointsRequest: Encodable {
    let amount: Int
    let note:   String?
}

struct BonusPointsResponse: Decodable {
    let member:       MemberPointsUpdate
    let historyEntry: PointsHistoryEntry
    let newMilestone: String?   // null if no milestone crossed
}

struct MemberPointsUpdate: Decodable {
    let id:            String
    let pointsTotal:   Int
    let pointsBalance: Int
}

// Milestones
struct Milestone {
    let value:       String   // "bronze"|"silver"|"gold"|"diamond"
    let displayName: String
    let emoji:       String
    let threshold:   Int

    static let all: [Milestone] = [
        Milestone(value: "bronze",  displayName: "Getting Started", emoji: "🥉", threshold: 100),
        Milestone(value: "silver",  displayName: "On a Roll",       emoji: "🥈", threshold: 250),
        Milestone(value: "gold",    displayName: "Star Helper",      emoji: "🥇", threshold: 500),
        Milestone(value: "diamond", displayName: "Family Legend",    emoji: "💎", threshold: 1000),
    ]

    static func from(_ value: String) -> Milestone? {
        all.first { $0.value == value }
    }
}

// Family goal (V2)
struct FamilyGoalContribution: Decodable {
    let memberId:     String
    let displayName:  String
    let color:        String
    let weeklyPoints: Int
}

struct FamilyGoal: Decodable, Identifiable {
    let id:                   String
    let familyId:             String
    var title:                String
    var emoji:                String?
    var pointsTarget:         Int
    var status:               String
    let contributions:        [FamilyGoalContribution]
    let combinedWeeklyPoints: Int
    let estimatedWeeks:       Int
    let createdAt:            Date
}
```

---

## 3. RewardsViewModel (Updated)

```swift
// Rewards/RewardsViewModel.swift
@MainActor
class RewardsViewModel: ObservableObject {
    @Published var leaderboard:          Leaderboard?
    @Published var rewards:              [Reward] = []
    @Published var pendingApprovals:     [Reward] = []
    @Published var catalog:              [RewardCatalogItem] = []
    @Published var familyGoal:           FamilyGoal?       // V2
    @Published var pendingMilestone:     String?           // triggers celebration sheet
    @Published var isLoading            = false
    @Published var errorMessage:         String?

    // Bonus points sheet state
    @Published var showBonusSheet        = false
    @Published var bonusTargetMember:    Profile?

    func loadAll(currentProfile: Profile) async {
        isLoading = true; defer { isLoading = false }
        async let lb:      ()  = loadLeaderboard()
        async let rw:      ()  = loadRewards()
        async let cat:     ()  = loadCatalog()
        await lb; await rw; await cat
    }

    func loadLeaderboard() async {
        do {
            leaderboard = try await APIClient.shared.get("/rewards/leaderboard")
        } catch { errorMessage = error.localizedDescription }
    }

    func loadRewards() async {
        do {
            let all: [Reward] = try await APIClient.shared.get("/rewards")
            rewards        = all.filter { $0.status != "pending_approval" }
            pendingApprovals = all.filter { $0.status == "pending_approval" }
        } catch { errorMessage = error.localizedDescription }
    }

    func loadCatalog() async {
        do {
            catalog = try await APIClient.shared.get("/rewards/catalog")
        } catch { errorMessage = error.localizedDescription }
    }

    // Reward actions
    func requestReward(_ reward: Reward) async {
        do {
            let updated: Reward = try await APIClient.shared.patch(
                "/rewards/\(reward.id)/request"
            )
            updateReward(updated)
        } catch APIError.conflict(let msg) {
            errorMessage = msg
        } catch { errorMessage = error.localizedDescription }
    }

    func approveReward(_ reward: Reward) async {
        do {
            let updated: Reward = try await APIClient.shared.patch(
                "/rewards/\(reward.id)/approve"
            )
            updateReward(updated)
            pendingApprovals.removeAll { $0.id == reward.id }
        } catch { errorMessage = error.localizedDescription }
    }

    func declineReward(_ reward: Reward) async {
        do {
            let updated: Reward = try await APIClient.shared.patch(
                "/rewards/\(reward.id)/decline"
            )
            updateReward(updated)
            pendingApprovals.removeAll { $0.id == reward.id }
        } catch { errorMessage = error.localizedDescription }
    }

    func redeemReward(_ reward: Reward) async {
        do {
            struct RedeemResponse: Decodable {
                let reward: Reward
                let member: MemberPointsUpdate
            }
            let res: RedeemResponse = try await APIClient.shared.patch(
                "/rewards/\(reward.id)/redeem"
            )
            updateReward(res.reward)
        } catch { errorMessage = error.localizedDescription }
    }

    func createReward(memberId: String, title: String, emoji: String?,
                      pointsCost: Int, catalogItemId: String?) async {
        struct CreateRewardRequest: Encodable {
            let memberId: String; let title: String; let emoji: String?
            let pointsCost: Int; let catalogItemId: String?
        }
        do {
            let r: Reward = try await APIClient.shared.post("/rewards",
                body: CreateRewardRequest(memberId: memberId, title: title,
                                          emoji: emoji, pointsCost: pointsCost,
                                          catalogItemId: catalogItemId))
            rewards.append(r)
        } catch { errorMessage = error.localizedDescription }
    }

    func deleteReward(_ reward: Reward) async {
        do {
            try await APIClient.shared.delete("/rewards/\(reward.id)")
            rewards.removeAll { $0.id == reward.id }
        } catch { errorMessage = error.localizedDescription }
    }

    // Bonus points
    func giveBonusPoints(toMemberId: String, amount: Int, note: String?) async {
        do {
            let res: BonusPointsResponse = try await APIClient.shared.post(
                "/members/\(toMemberId)/bonus-points",
                body: BonusPointsRequest(amount: amount, note: note)
            )
            if let milestone = res.newMilestone {
                pendingMilestone = milestone
            }
            showBonusSheet = false
        } catch { errorMessage = error.localizedDescription }
    }

    // Helpers
    private func updateReward(_ updated: Reward) {
        if let i = rewards.firstIndex(where: { $0.id == updated.id }) {
            rewards[i] = updated
        }
    }
}
```

---

## 4. Screen: RewardsView (Parent)

**File:** `Rewards/RewardsView.swift`
**API calls:** `GET /api/rewards/leaderboard`, `GET /api/rewards`, `GET /api/rewards/catalog`
**Actions:** approve, decline, redeem, give bonus points

### Layout (ScrollView, pull-to-refresh)

Four sections rendered in order:

#### Section 1 — Leaderboard

```
"This week's leaderboard 🏆"

┌──────────────────────────────────┐
│ 🥇  L  Liam     145 total  62 wk│  ← rank | avatar | name | total | weekly
│ 🥈  E  Emma     110 total  38 wk│
│ 🥉  S  Sarah     90 total  20 wk│
└──────────────────────────────────┘
```

- White card, border `#E2E8F0`
- Weekly points (bold blue) are the ranking key
- Total all-time (muted gray) shown as secondary info
- All family members shown — parents included
- Medal emoji for top 3, numbered rank for 4+
- Tap any child row → opens `BonusPointsSheet` for that child

#### Section 2 — Pending Approvals

Only shown when `pendingApprovals.count > 0`. Amber `#FEF3C7` background,
`#FCD34D` border:

```
"Pending approvals ⏳"

┌────────────────────────────────────────┐
│  L  🎬 Movie night        100 pts cost │
│     Liam · balance: 82 pts             │
│  ┌──────────────┐  ┌─────────────────┐ │
│  │ ✓ Approve   │  │    Decline      │ │
│  └──────────────┘  └─────────────────┘ │
└────────────────────────────────────────┘
```

- One card per pending reward
- Shows member's current `pointsBalance` so parent can confirm sufficiency
- "Approve" → green, calls `approveReward()`
- "Decline" → secondary outlined, calls `declineReward()`
- Declined rewards revert to `active` — goal preserved, child tries again

#### Section 3 — Goals

All non-pending active/approved rewards, grouped by child:

```
"Goals"

L  Liam
   🎬 Movie night — 100 pts
   ████████████░░  82/100 · pending ⏳
   [no action — already pending]

E  Emma
   🎮 New game — 200 pts
   ████████░░░░░░  45/200 · 155 to go
   [Remind to claim]  (shown if affordable)
```

- Progress bar uses `member.pointsBalance` (spendable) ÷ `reward.pointsCost`
- "Remind to claim" shown if balance >= cost and status == active (not yet claimed)
- Tap a goal → `RewardDetailSheet` with edit / delete options

#### Section 4 — Streaks

```
"Streaks 🔥"

┌─────────────────────────────────┐
│  L  Liam     All done today ✓   🔥 5 days  │
│  E  Emma     Missed yesterday   🔸 3 grace │
│  J  Jake     Streak ended       —  0 days  │
└─────────────────────────────────┘
```

Three visual states per row — see StreakRowView component below.

**"+ Goal" header button** → opens `SetGoalView`

```swift
// Rewards/RewardsView.swift
struct RewardsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = RewardsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DotoNavHeader(title: "Rewards", trailing: {
                AnyView(Button("+ Goal") {
                    // navigate to SetGoalView
                })
            })

            if vm.isLoading && vm.leaderboard == nil {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let lb = vm.leaderboard {
                            LeaderboardCard(
                                leaderboard: lb,
                                onMemberTap: { member in
                                    if member.role == "child" {
                                        vm.bonusTargetMember = member as? Profile
                                        vm.showBonusSheet = true
                                    }
                                }
                            )
                        }

                        if !vm.pendingApprovals.isEmpty {
                            PendingApprovalsSection(
                                rewards: vm.pendingApprovals,
                                onApprove: { Task { await vm.approveReward($0) } },
                                onDecline: { Task { await vm.declineReward($0) } }
                            )
                        }

                        GoalsSection(rewards: vm.rewards, members: vm.leaderboard?.entries ?? [])

                        StreaksSection(members: /* from leaderboard entries */ [])
                    }
                    .padding(14)
                }
                .refreshable { await vm.loadAll(currentProfile: authVM.currentProfile!) }
            }
        }
        .sheet(isPresented: $vm.showBonusSheet) {
            if let member = vm.bonusTargetMember {
                BonusPointsSheet(targetMember: member, allChildren: []) { amount, note in
                    Task { await vm.giveBonusPoints(toMemberId: member.id,
                                                     amount: amount, note: note) }
                }
            }
        }
        .sheet(item: Binding(get: { vm.pendingMilestone.map { MilestoneWrapper(value: $0) } },
                              set: { _ in vm.pendingMilestone = nil })) { wrapper in
            MilestoneCelebrationView(milestoneValue: wrapper.value) {
                vm.pendingMilestone = nil
            }
        }
        .task { await vm.loadAll(currentProfile: authVM.currentProfile!) }
    }
}

struct MilestoneWrapper: Identifiable { var id: String { value }; let value: String }
```

---

## 5. Screen: RewardsView (Child)

The same `RewardsView` switches layout based on `currentProfile.isChild`.

### Child Layout

#### Header — Balance summary inline

```
Rewards                          82
                            pts to spend
```

Points balance shown right-aligned in the dark navy header.

#### Section 1 — Balance Card

```
┌────────────────────────────────────┐
│         ALL-TIME EARNED            │
│              145                   │  ← large, prominent
│             points                 │
│                                    │
│  82 to spend  │  🔥 5  │  🥇 1st  │
│    (balance)  │ (streak)│  (rank)  │
└────────────────────────────────────┘
```

Three stats side-by-side with vertical dividers. The large `145` never
decreases — always feels like an achievement. The `82` is the spendable
balance used for goal progress.

#### Section 2 — My Goals

Active and pending goals for this child only. Each card shows:
- Emoji + title + cost
- Progress bar using `pointsBalance` ÷ `pointsCost`
- "X / Y pts · Z to go" label
- "Claim! 🎉" button when affordable and status == active
- "Pending ⏳" tag when status == pending_approval

#### Section 3 — Leaderboard

Same leaderboard card as parent view but read-only. Child's own row gets
a dark ring avatar border and "(you)" suffix on name.

#### Footer Link

"View my points history →" — navigates to `PointsHistoryView`.

---

## 6. Screen: PointsHistoryView (New)

**File:** `Rewards/PointsHistoryView.swift`
**API call:** `GET /api/members/:id/points-history`

### Layout

```
← Liam's history                    145

Today
  ✓  Take out trash             +10
  🎁 Science test bonus         +25    ← "from Mum" subtitle
     Science test A+ — so proud!
  ✓  Homework — Ch.4            +15

Yesterday
  ✓  Make bed                    +5
  🎟 Movie night redeemed      −100    ← "approved by Mum" subtitle
```

Items grouped by calendar day. Within each day, sorted by `createdAt DESC`.

**Milestone entries** appear as teal cards inline in the day group:

```
  ┌──────────────────────────────────┐
  │ 🥇  Star Helper — 500pts reached │
  │     Mon 24 Mar                   │
  └──────────────────────────────────┘
```

**Pagination:** Initial load is 50 entries. "Load more" button at bottom when
`hasMore == true`. Calls same endpoint with `before = response.nextBefore`.

```swift
// Rewards/PointsHistoryView.swift
struct PointsHistoryView: View {
    let memberId:    String
    let displayName: String

    @StateObject private var vm = PointsHistoryViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DotoNavHeader(
                title: "\(displayName)'s history",
                trailing: {
                    AnyView(Text("\(vm.history?.pointsTotal ?? 0) pts")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white))
                }
            )

            if vm.isLoading && vm.groupedEntries.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(vm.groupedEntries, id: \.date) { group in
                        Section(header: Text(group.dateLabel)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color.textMuted)) {
                            ForEach(group.entries) { entry in
                                PointsHistoryRow(entry: entry)
                            }
                        }
                    }

                    if vm.hasMore {
                        Button("Load more") {
                            Task { await vm.loadMore() }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .listStyle(.plain)
            }
        }
        .task { await vm.load(memberId: memberId) }
    }
}

// Row component
struct PointsHistoryRow: View {
    let entry: PointsHistoryEntry

    var body: some View {
        if entry.eventType == "milestone" {
            MilestoneHistoryCard(milestoneName: entry.note ?? "")
        } else {
            HStack(spacing: 12) {
                Image(systemName: entry.icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: entry.iconColor))
                    .frame(width: 24, height: 24)
                    .background(Color(hex: entry.iconColor).opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.note ?? entry.eventType.capitalized)
                        .font(.system(size: 13))
                        .foregroundColor(Color.textPrimary)
                    if let note = entry.note, entry.eventType == "bonus" {
                        Text("Bonus from parent")
                            .font(.system(size: 11))
                            .foregroundColor(Color.textMuted)
                    }
                }

                Spacer()

                Text(entry.isEarning ? "+\(entry.amount)" : "\(entry.amount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(entry.isEarning
                        ? Color(hex: "#1D9E75")
                        : Color(hex: "#E24B4A"))
            }
            .padding(.vertical, 4)
        }
    }
}
```

---

## 7. Sheet: BonusPointsSheet (New)

**File:** `Rewards/BonusPointsSheet.swift`
**Shown:** Bottom sheet when parent taps a child's row in the leaderboard

### Layout

```
[ drag handle ]
Give bonus points

For:   [L Liam]  [E Emma — dimmed]

Points:
[−]     25     [+]
[+5] [+10] [+25 ●] [+50]

Note (shown to Liam):
[ Science test A+ — so proud! 🎉  ]

[  Give 25 bonus points to Liam  ]
```

```swift
// Rewards/BonusPointsSheet.swift
struct BonusPointsSheet: View {
    let targetMember: Profile
    let allChildren:  [Profile]
    let onSubmit:     (Int, String?) -> Void

    @State private var selectedMemberId: String
    @State private var amount            = 25
    @State private var note              = ""
    @Environment(\.dismiss) private var dismiss

    private let presets = [5, 10, 25, 50]

    init(targetMember: Profile, allChildren: [Profile], onSubmit: @escaping (Int, String?) -> Void) {
        self.targetMember    = targetMember
        self.allChildren     = allChildren
        self.onSubmit        = onSubmit
        _selectedMemberId    = State(initialValue: targetMember.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Drag handle
            Capsule().fill(Color.cardBorder)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text("Give bonus points")
                .font(.system(size: 17, weight: .semibold))
                .padding(.horizontal, 20)

            // Member selector
            if allChildren.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("For").font(.system(size: 12)).foregroundColor(Color.textMuted)
                        .padding(.horizontal, 20)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(allChildren) { child in
                                VStack(spacing: 4) {
                                    AvatarView(name: child.displayName, color: child.color,
                                               size: 32, isActive: selectedMemberId == child.id)
                                    Text(child.displayName).font(.system(size: 9))
                                        .foregroundColor(selectedMemberId == child.id
                                            ? Color.memberBlue : Color.textMuted)
                                }
                                .onTapGesture { selectedMemberId = child.id }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }

            // Amount stepper + presets
            VStack(alignment: .leading, spacing: 8) {
                Text("Points").font(.system(size: 12)).foregroundColor(Color.textMuted)
                    .padding(.horizontal, 20)

                HStack(spacing: 16) {
                    Button { if amount > 1 { amount -= 1 } } label: {
                        Image(systemName: "minus").frame(width: 32, height: 32)
                            .background(Color.screenBg).cornerRadius(8)
                    }
                    Text("\(amount)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.memberBlue)
                        .frame(minWidth: 60, alignment: .center)
                    Button { if amount < 500 { amount += 1 } } label: {
                        Image(systemName: "plus").frame(width: 32, height: 32)
                            .background(Color.screenBg).cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        Button("+\(preset)") { amount = preset }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(amount == preset ? Color.memberBlue : Color.selectedDayBg)
                            .foregroundColor(amount == preset ? .white : Color.memberBlue)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
            }

            // Note field
            VStack(alignment: .leading, spacing: 6) {
                Text("Note (shown to \(targetMember.displayName))")
                    .font(.system(size: 12)).foregroundColor(Color.textMuted)
                    .padding(.horizontal, 20)
                TextField("What did they do well?", text: $note)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder))
                    .padding(.horizontal, 20)
            }

            Button {
                onSubmit(amount, note.isEmpty ? nil : note)
            } label: {
                Text("Give \(amount) bonus points to \(targetMember.displayName)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.white)
    }
}
```

---

## 8. Screen: SetGoalView (Updated)

**File:** `Rewards/SetGoalView.swift`
**API calls:** `GET /api/rewards/catalog`, `POST /api/rewards`

Three-tier layout. Previous goals → Family catalog → Custom form.

### Layout

```
← Set a goal            82 pts to spend

Your previous goals (horizontal scroll)
[ 🎬 Movie night  100pts ]  [ 🎮 New game  200pts ]

Family catalog
[ 🍕 Choose dinner         50 pts  →  ]
[ 📱 Extra screen time     75 pts  →  ]
[ 🛌 Stay up late (Fri)    80 pts  →  ]

Or create your own
[ What do you want to earn?      ]
[ Points needed: 100             ]
[ Set this as my goal            ]
```

```swift
// Rewards/SetGoalView.swift
struct SetGoalView: View {
    let memberId:       String
    let memberBalance:  Int
    let previousGoals:  [Reward]   // previously redeemed rewards for this child
    @ObservedObject var vm: RewardsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var customTitle  = ""
    @State private var customCost   = 100
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 0) {
            DotoNavHeader(
                title: "Set a goal",
                trailing: {
                    AnyView(Text("\(memberBalance) pts to spend")
                        .font(.system(size: 11))
                        .foregroundColor(Color.appNavySub))
                }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Tier 1 — Previous goals
                    if !previousGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader("Your previous goals")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(previousGoals) { goal in
                                        PreviousGoalChip(goal: goal) {
                                            Task {
                                                await vm.createReward(
                                                    memberId: memberId,
                                                    title: goal.title,
                                                    emoji: goal.emoji,
                                                    pointsCost: goal.pointsCost,
                                                    catalogItemId: nil
                                                )
                                                dismiss()
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // Tier 2 — Family catalog
                    if !vm.catalog.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader("Family catalog")
                            VStack(spacing: 1) {
                                ForEach(vm.catalog) { item in
                                    CatalogItemRow(item: item, memberBalance: memberBalance) {
                                        Task {
                                            await vm.createReward(
                                                memberId: memberId,
                                                title: item.title,
                                                emoji: item.emoji,
                                                pointsCost: item.pointsCost,
                                                catalogItemId: item.id
                                            )
                                            dismiss()
                                        }
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder))
                        }
                        .padding(.horizontal, 16)
                    }

                    // Tier 3 — Custom
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader("Or create your own")
                        VStack(spacing: 10) {
                            TextField("What do you want to earn?", text: $customTitle)
                                .font(.system(size: 14))
                                .padding(12)
                                .background(Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder))

                            HStack {
                                Text("Points needed:")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.textSecondary)
                                Spacer()
                                Stepper("\(customCost)", value: $customCost, in: 5...500, step: 5)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding(12)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder))

                            Button {
                                guard !customTitle.isEmpty else { return }
                                isSubmitting = true
                                Task {
                                    await vm.createReward(
                                        memberId: memberId,
                                        title: customTitle,
                                        emoji: nil,
                                        pointsCost: customCost,
                                        catalogItemId: nil
                                    )
                                    isSubmitting = false
                                    dismiss()
                                }
                            } label: {
                                Text(isSubmitting ? "Setting goal..." : "Set this as my goal")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(customTitle.isEmpty || isSubmitting)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
    }
}

struct PreviousGoalChip: View {
    let goal: Reward; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(goal.emoji ?? "🎯").font(.system(size: 20))
                Text(goal.title).font(.system(size: 8, weight: .semibold))
                    .foregroundColor(Color(hex: "#412402")).multilineTextAlignment(.center)
                    .lineLimit(2).frame(width: 60)
                Text("\(goal.pointsCost) pts").font(.system(size: 8))
                    .foregroundColor(Color(hex: "#633806"))
            }
            .padding(8)
            .background(Color(hex: "#FAEEDA"))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#FAC775")))
            .cornerRadius(8)
        }
    }
}

struct CatalogItemRow: View {
    let item: RewardCatalogItem; let memberBalance: Int; let onTap: () -> Void
    var canAfford: Bool { memberBalance >= item.pointsCost }
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(item.emoji ?? "🎯").font(.system(size: 18))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                    Text("\(item.pointsCost) pts")
                        .font(.system(size: 11))
                        .foregroundColor(canAfford ? Color(hex: "#1D9E75") : Color.textMuted)
                }
                Spacer()
                Text("Set goal →").font(.system(size: 12)).foregroundColor(Color.memberBlue)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
        }
        .background(Color.white)
    }
}
```

---

## 9. Screen: RewardCatalogView (New)

**File:** `Rewards/RewardCatalogView.swift`
**Route:** Settings → Rewards → Manage catalog
**API calls:** `GET /api/rewards/catalog`, `POST`, `PUT`, `DELETE /api/rewards/catalog/:id`

### Layout

- List of current catalog items with swipe-left to delete
- "Quick-add" suggestion chips at the bottom for common rewards
- "+ Add" nav button → sheet with title + emoji + points cost fields

```swift
// Rewards/RewardCatalogView.swift
struct RewardCatalogView: View {
    @StateObject private var vm = RewardCatalogViewModel()

    private let suggestions: [(emoji: String, title: String, cost: Int)] = [
        ("🎬", "Movie night",        100),
        ("🍕", "Choose dinner",       50),
        ("📱", "Extra screen time",   75),
        ("🛌", "Stay up late (Fri)",  80),
        ("🎡", "Day out",            300),
        ("👫", "Friend sleepover",   150),
        ("🧹", "Day off chores",      60),
        ("📚", "New book",            80),
    ]

    var body: some View {
        VStack(spacing: 0) {
            DotoNavHeader(title: "Reward catalog", trailing: {
                AnyView(Button("+ Add") { vm.showAddSheet = true })
            })

            if vm.items.isEmpty && !vm.isLoading {
                Text("No rewards in the catalog yet.\nAdd some for your children to choose from.")
                    .font(.system(size: 14)).foregroundColor(Color.textMuted)
                    .multilineTextAlignment(.center).padding(32)
            } else {
                List {
                    Section {
                        ForEach(vm.items) { item in
                            CatalogManageRow(item: item,
                                onEdit: { vm.editingItem = item; vm.showAddSheet = true },
                                onDelete: { Task { await vm.deleteItem(item) } })
                        }
                    }

                    Section(header: Text("Quick-add suggestions")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.textMuted)) {
                        FlowLayout(suggestions.map { s in
                            SuggestionChip(emoji: s.emoji, title: s.title, cost: s.cost) {
                                Task { await vm.addItem(emoji: s.emoji,
                                                         title: s.title,
                                                         cost: s.cost) }
                            }
                        })
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .sheet(isPresented: $vm.showAddSheet) {
            AddCatalogItemSheet(editingItem: vm.editingItem, onSave: { emoji, title, cost in
                Task { await vm.editingItem == nil
                    ? vm.addItem(emoji: emoji, title: title, cost: cost)
                    : vm.updateItem(id: vm.editingItem!.id, emoji: emoji,
                                     title: title, cost: cost) }
                vm.showAddSheet = false
            })
        }
        .task { await vm.load() }
    }
}
```

---

## 10. Screen: MilestoneCelebrationView (New)

**File:** `Rewards/MilestoneCelebrationView.swift`
**Shown:** Full-screen sheet over any view when `pendingMilestone` is set in `RewardsViewModel`
**Trigger:** Any API call that modifies points returns a `newMilestone` field

### Layout

Full navy-to-blue gradient. Large emoji centred. Badge name + achievement text.
Progress dots showing the milestone track. Single button to dismiss.

```swift
// Rewards/MilestoneCelebrationView.swift
struct MilestoneCelebrationView: View {
    let milestoneValue: String
    let onDismiss: () -> Void

    private var milestone: Milestone? { Milestone.from(milestoneValue) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appNavy, Color.memberBlue],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Text(milestone?.emoji ?? "🏅")
                    .font(.system(size: 72))

                VStack(spacing: 8) {
                    Text(milestone?.displayName ?? "Achievement!")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    Text("You've earned \(milestone?.threshold ?? 0) points all-time!")
                        .font(.system(size: 14))
                        .foregroundColor(Color.appNavySub)
                        .multilineTextAlignment(.center)
                }

                // Milestone progress track
                MilestoneProgressTrack(currentMilestone: milestoneValue)

                Spacer()

                Button(action: onDismiss) {
                    Text("Awesome! 🎉")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.appNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 28)
        }
    }
}

struct MilestoneProgressTrack: View {
    let currentMilestone: String

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(Milestone.all.enumerated()), id: \.offset) { index, m in
                let isEarned = isEarnedOrPast(m.value)
                let isCurrent = m.value == currentMilestone

                VStack(spacing: 4) {
                    Text(m.emoji).font(.system(size: isCurrent ? 26 : 18))
                        .opacity(isEarned ? 1.0 : 0.35)
                    Text("\(m.threshold)").font(.system(size: 8))
                        .foregroundColor(isEarned ? .white : Color.appNavySub.opacity(0.5))
                }

                if index < Milestone.all.count - 1 {
                    Rectangle().fill(Color.white.opacity(isEarned ? 0.4 : 0.15))
                        .frame(width: 24, height: 1)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.12))
        .cornerRadius(12)
    }

    private func isEarnedOrPast(_ value: String) -> Bool {
        let order = ["bronze", "silver", "gold", "diamond"]
        guard let currentIdx = order.firstIndex(of: currentMilestone),
              let checkIdx   = order.firstIndex(of: value) else { return false }
        return checkIdx <= currentIdx
    }
}
```

---

## 11. Component: StreakRowView

Used inside the Streaks section of both parent and child views.

```swift
// Rewards/StreakRowView.swift
struct StreakRowView: View {
    let member: LeaderboardEntry

    var streakColor: Color {
        switch member.streakStatus ?? "none" {
        case "active": return Color.memberAmber
        case "grace":  return Color.memberAmber
        default:       return Color.textMuted
        }
    }

    var streakIcon: String {
        switch member.streakStatus ?? "none" {
        case "active": return "🔥"
        case "grace":  return "🔸"
        default:       return "—"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: member.displayName, color: member.color, size: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                if let status = member.streakStatus {
                    Text(streakSubtitle(status: status))
                        .font(.system(size: 10))
                        .foregroundColor(status == "grace" ? Color.memberAmber : Color.textMuted)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Text(streakIcon).font(.system(size: 14))
                Text(streakValueLabel)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(streakColor)
            }
        }
        .padding(.vertical, 6)
    }

    var streakValueLabel: String {
        guard let status = member.streakStatus else { return "0 days" }
        switch status {
        case "active": return "\(member.streak ?? 0) days"
        case "grace":  return "\(member.streak ?? 0) grace"
        default:       return "0 days"
        }
    }

    func streakSubtitle(status: String) -> String {
        switch status {
        case "active": return "All tasks done today ✓"
        case "grace":  return "Missed yesterday — 1 day to recover"
        default:       return "Streak ended — start again today"
        }
    }
}
```

---

## 12. Complete File List

```
Rewards/
├── RewardsView.swift               ← Updated (parent + child branching)
├── RewardsViewModel.swift          ← Updated (all new actions)
├── PointsHistoryView.swift         ← New
├── PointsHistoryViewModel.swift    ← New
├── BonusPointsSheet.swift          ← New
├── SetGoalView.swift               ← Updated (3-tier)
├── RewardCatalogView.swift         ← New
├── RewardCatalogViewModel.swift    ← New
├── MilestoneCelebrationView.swift  ← New
├── FamilyGoalCard.swift            ← New (V2, used inline in RewardsView)
└── Components/
    ├── LeaderboardCard.swift       ← New (extracted from RewardsView)
    ├── PendingApprovalsSection.swift ← New
    ├── GoalsSection.swift          ← New
    ├── StreakRowView.swift          ← New
    ├── PreviousGoalChip.swift      ← New
    ├── CatalogItemRow.swift        ← New
    └── MilestoneProgressTrack.swift ← New

Models/
└── RewardsModels.swift             ← New (all reward-related Codable types)

Models/
└── Profile.swift                   ← Updated (pointsTotal, pointsBalance, streakStatus)
```
