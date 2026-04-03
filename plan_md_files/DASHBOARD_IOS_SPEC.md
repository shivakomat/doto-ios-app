# Doto — Dashboard iOS Spec (Improved)
**Version:** 1.0
**Scope:** Parent and child dashboard screens — all sections, components, states
**Replaces:** Screen 05 (DashboardView) in core IOS_SPEC.md

---

## 1. File Structure

```
Dashboard/
├── DashboardView.swift              ← Root — branches on currentProfile.role
├── DashboardViewModel.swift         ← Updated — new response models
├── ParentDashboardView.swift        ← New — full parent layout
├── ChildDashboardView.swift         ← New — full child layout
└── Components/
    ├── FiveDayStripView.swift       ← New
    ├── OverdueAlertBanner.swift     ← New
    ├── RecentTasksSection.swift     ← New
    ├── FamilyProgressSection.swift  ← New
    ├── ShoppingNudgeCard.swift      ← New
    ├── PendingApprovalNudge.swift   ← New
    ├── ChildStatsCard.swift         ← New
    ├── ChildGoalCard.swift          ← New
    ├── ChildTasksSection.swift      ← New
    ├── ChildEventsSection.swift     ← New
    └── FamilyMembersRow.swift       ← New
```

---

## 2. Data Models

### 2.1 Parent Dashboard Response

```swift
// Models/DashboardModels.swift

struct ParentDashboardResponse: Decodable {
    let profile:           DashboardProfile
    let family:            DashboardFamily
    let upcomingEvents:    UpcomingEvents
    let overdueCount:      Int
    let recentTasks:       [DashboardTask]
    let familyProgress:    [MemberProgress]
    let shoppingNudge:     ShoppingNudge?       // null = hide
    let pendingApprovals:  [PendingApproval]    // empty = hide
}

struct DashboardFamily: Decodable {
    let id:      String
    let name:    String
    let members: [FamilyMemberSummary]
}

struct FamilyMemberSummary: Decodable, Identifiable {
    let id:           String
    let displayName:  String
    let role:         String
    let color:        String
    let pointsTotal:  Int
    let streak:       Int
    let streakStatus: String
}

struct UpcomingEvents: Decodable {
    let days: [DashboardDay]
}

struct DashboardDay: Decodable, Identifiable {
    var id: String { date }
    let date:         String        // "2026-03-26"
    let dayLabel:     String        // "Thu"
    let dayNumber:    String        // "26"
    let isToday:      Bool
    let hasConflict:  Bool
    let memberColors: [String]      // up to 3 hex colours
    let events:       [DashboardEvent]
}

struct DashboardEvent: Decodable, Identifiable {
    let id:            String
    let title:         String
    let startAt:       Date
    let endAt:         Date
    let location:      String?
    let assignedTo:    [String]
    let isConflicting: Bool

    var durationMinutes: Int {
        Int(endAt.timeIntervalSince(startAt) / 60)
    }
}

struct DashboardTask: Decodable, Identifiable {
    let id:            String
    let title:         String
    let assignedTo:    String?
    let assigneeName:  String?
    let assigneeColor: String?
    let priority:      String
    let points:        Int
    let dueAt:         Date
    let status:        String
    let isOverdue:     Bool
}

struct MemberProgress: Decodable, Identifiable {
    var id: String { memberId }
    let memberId:       String
    let displayName:    String
    let color:          String
    let tasksCompleted: Int
    let tasksTotal:     Int

    var progressFraction: Double {
        guard tasksTotal > 0 else { return 0 }
        return Double(tasksCompleted) / Double(tasksTotal)
    }
}

struct ShoppingNudge: Decodable {
    let listId:        String
    let listName:      String
    let uncheckedCount: Int
    let lastUpdatedAt: Date
}

struct PendingApproval: Decodable, Identifiable {
    let id:            String
    let memberId:      String
    let memberName:    String
    let memberColor:   String
    let title:         String
    let emoji:         String?
    let pointsCost:    Int
    let memberBalance: Int
    let requestedAt:   Date
}

struct DashboardProfile: Decodable {
    let id:            String
    let displayName:   String
    let color:         String
    let role:          String
    let pointsTotal:   Int
    let pointsBalance: Int
}
```

### 2.2 Child Dashboard Response

```swift
struct ChildDashboardResponse: Decodable {
    let profile:        DashboardProfile
    let stats:          ChildStats
    let activeGoal:     ActiveGoal?          // null = hide
    let todaysTasks:    [ChildTask]
    let upcomingEvents: [DashboardEvent]
    let familyMembers:  [FamilyMemberRow]
}

struct ChildStats: Decodable {
    let weeklyPoints: Int
    let weeklyRank:   Int
    let totalMembers: Int
}

struct ActiveGoal: Decodable {
    let id:          String
    let title:       String
    let emoji:       String?
    let pointsCost:  Int
    let status:      String     // "active"|"pending_approval"|"approved"
    let progressPct: Int        // 0–100, clamped server-side
}

struct ChildTask: Decodable, Identifiable {
    let id:        String
    let title:     String
    let points:    Int
    let status:    String
    let dueAt:     Date
    let isOverdue: Bool

    var isDone: Bool { status == "done" }
}

struct FamilyMemberRow: Decodable, Identifiable {
    let id:           String
    let displayName:  String
    let color:        String
    let role:         String
    let weeklyPoints: Int
    let streak:       Int
    let streakStatus: String
    let isSelf:       Bool

    var streakDisplay: String {
        switch streakStatus {
        case "active": return "🔥 \(streak)"
        case "grace":  return "🔸 \(streak)"
        default:       return "\(weeklyPoints) pts"
        }
    }
}
```

---

## 3. DashboardViewModel (Updated)

```swift
// Dashboard/DashboardViewModel.swift
@MainActor
class DashboardViewModel: ObservableObject {

    // Parent data
    @Published var parentData: ParentDashboardResponse?

    // Child data
    @Published var childData: ChildDashboardResponse?

    // Shared state
    @Published var isLoading        = false
    @Published var errorMessage:    String?
    @Published var selectedDayIndex = 0     // which day is expanded in 5-day strip

    // Child task completion (optimistic)
    @Published var completingTaskIds: Set<String> = []

    func load(role: String) async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            if role == "parent" {
                parentData = try await APIClient.shared.get("/dashboard")
            } else {
                childData = try await APIClient.shared.get("/dashboard")
            }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Child completes a task from dashboard — optimistic UI
    func completeTask(_ task: ChildTask) async {
        guard !completingTaskIds.contains(task.id) else { return }
        completingTaskIds.insert(task.id)

        // Optimistic: update local state immediately
        if let idx = childData?.todaysTasks.firstIndex(where: { $0.id == task.id }) {
            childData?.todaysTasks[idx] = ChildTask(
                id: task.id, title: task.title, points: task.points,
                status: "done", dueAt: task.dueAt, isOverdue: false
            )
            // Also update stats locally
            childData?.profile.pointsBalance += task.points
            childData?.stats.weeklyPoints    += task.points
        }

        do {
            let _: DotoTask = try await APIClient.shared.patch(
                "/tasks/\(task.id)/complete"
            )
        } catch {
            // Revert on failure
            await load(role: "child")
        }

        completingTaskIds.remove(task.id)
    }

    var selectedDay: DashboardDay? {
        parentData?.upcomingEvents.days[safe: selectedDayIndex]
    }
}

// Safe subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```

---

## 4. DashboardView (Root)

```swift
// Dashboard/DashboardView.swift
struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = DashboardViewModel()

    var body: some View {
        Group {
            if authVM.currentProfile?.isParent == true {
                ParentDashboardView(vm: vm)
            } else {
                ChildDashboardView(vm: vm)
            }
        }
        .task {
            let role = authVM.currentProfile?.role ?? "parent"
            await vm.load(role: role)
        }
    }
}
```

---

## 5. ParentDashboardView

**File:** `Dashboard/ParentDashboardView.swift`

```swift
// Dashboard/ParentDashboardView.swift
struct ParentDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject var vm: DashboardViewModel
    @State private var showFABSheet = false

    var data: ParentDashboardResponse? { vm.parentData }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Dark navy header
                ParentDashboardHeader(
                    profile: data?.profile,
                    members: data?.family.members ?? [],
                    onAvatarTap: { /* navigate to settings */ }
                )

                if vm.isLoading && data == nil {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let d = data {
                    // Empty state — no events AND no recent tasks
                    if d.upcomingEvents.days.allSatisfy({ $0.events.isEmpty }) &&
                       d.recentTasks.isEmpty {
                        ParentEmptyDashboard()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                // 1. AI conflict card (if applicable — from a_cards table in V1.5)
                                // Omitted for MVP — shown when AI is enabled

                                // 2. 5-day schedule strip
                                FiveDayStripView(
                                    days: d.upcomingEvents.days,
                                    selectedIndex: $vm.selectedDayIndex,
                                    members: d.family.members
                                )

                                // 3. Overdue alert
                                if d.overdueCount > 0 {
                                    OverdueAlertBanner(count: d.overdueCount)
                                }

                                // 4. Recently assigned tasks
                                if !d.recentTasks.isEmpty {
                                    RecentTasksSection(tasks: d.recentTasks)
                                }

                                // 5. Family weekly progress
                                if !d.familyProgress.isEmpty {
                                    FamilyProgressSection(progress: d.familyProgress)
                                }

                                // 6. Shopping nudge
                                if let nudge = d.shoppingNudge {
                                    ShoppingNudgeCard(nudge: nudge)
                                }

                                // 7. Pending reward approvals
                                ForEach(d.pendingApprovals) { approval in
                                    PendingApprovalNudge(approval: approval)
                                }
                            }
                            .padding(14)
                            .padding(.bottom, 60) // space for FAB
                        }
                        .refreshable { await vm.load(role: "parent") }
                    }
                }
            }

            // FAB
            FABButton { showFABSheet = true }
                .padding(20)
        }
        .sheet(isPresented: $showFABSheet) {
            FABBottomSheet()
        }
    }
}
```

---

## 6. Component: ParentDashboardHeader

```swift
// Dashboard/Components/ParentDashboardHeader.swift
struct ParentDashboardHeader: View {
    let profile: DashboardProfile?
    let members: [FamilyMemberSummary]
    let onAvatarTap: () -> Void

    @State private var activeFilterId: String?   // nil = show all

    var body: some View {
        VStack(spacing: 0) {
            // Greeting row
            ZStack {
                Color.appNavy
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Date().greeting), \(profile?.displayName ?? "") \(Date().greetingEmoji)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text(Date().dashboardDateLabel)
                            .font(.system(size: 10))
                            .foregroundColor(Color.appNavySub)
                    }
                    Spacer()
                    Button(action: onAvatarTap) {
                        AvatarView(
                            name: profile?.displayName ?? "",
                            color: profile?.color ?? "#185FA5",
                            size: 28
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }

            // Avatar filter row
            if !members.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(members) { member in
                            AvatarView(
                                name: member.displayName,
                                color: member.color,
                                size: 26,
                                isActive: activeFilterId == member.id
                            )
                            .onTapGesture {
                                activeFilterId = activeFilterId == member.id
                                    ? nil : member.id
                            }
                        }
                        // Invite "+" button
                        Circle()
                            .fill(Color.cardBorder)
                            .frame(width: 26, height: 26)
                            .overlay(Text("+").font(.system(size: 14)).foregroundColor(Color.textMuted))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .background(Color.appNavy)
            }
        }
    }
}

extension Date {
    var greetingEmoji: String {
        let h = Calendar.current.component(.hour, from: self)
        switch h {
        case 5..<12:  return "☀️"
        case 12..<17: return "🌤"
        default:      return "🌙"
        }
    }

    var dashboardDateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: self)
    }
}
```

---

## 7. Component: FiveDayStripView

```swift
// Dashboard/Components/FiveDayStripView.swift
struct FiveDayStripView: View {
    let days:           [DashboardDay]
    @Binding var selectedIndex: Int
    let members:        [FamilyMemberSummary]

    var body: some View {
        VStack(spacing: 0) {
            // Day selector header
            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    DayColumn(
                        day:        day,
                        isSelected: index == selectedIndex,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedIndex = selectedIndex == index ? -1 : index
                            }
                        }
                    )
                    if index < days.count - 1 {
                        Divider().frame(height: 50)
                    }
                }
            }
            .background(Color.white)

            // Expanded events for selected day
            if selectedIndex >= 0, let day = days[safe: selectedIndex] {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text(fullDayLabel(day))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.textMuted)
                        .padding(.horizontal, 10)
                        .padding(.top, 8)

                    if day.events.isEmpty {
                        Text("No events")
                            .font(.system(size: 11))
                            .foregroundColor(Color.textMuted)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 8)
                    } else {
                        ForEach(day.events.prefix(3)) { event in
                            DashboardEventRow(event: event, members: members)
                                .padding(.horizontal, 10)
                        }
                        if day.events.count > 3 {
                            HStack {
                                Spacer()
                                NavigationLink("+ \(day.events.count - 3) more → See all") {
                                    // Navigate to Schedule tab with this day selected
                                }
                                .font(.system(size: 11))
                                .foregroundColor(Color.memberBlue)
                            }
                            .padding(.horizontal, 10)
                        }
                        Spacer().frame(height: 8)
                    }
                }
                .background(Color.white)
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
    }

    private func fullDayLabel(_ day: DashboardDay) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: day.date) else { return day.dayLabel }
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: date)
    }
}

struct DayColumn: View {
    let day:        DashboardDay
    let isSelected: Bool
    let onTap:      () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Text(day.dayLabel)
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

struct DashboardEventRow: View {
    let event:   DashboardEvent
    let members: [FamilyMemberSummary]

    private var assigneeColor: String {
        event.assignedTo.first.flatMap { id in
            members.first { $0.id == id }?.color
        } ?? "#94A3B8"
    }

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(event.isConflicting ? Color.conflictBorder : Color(hex: assigneeColor))
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 2) {
                Text((event.isConflicting ? "⚠ " : "") + event.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(event.isConflicting ? Color.conflictText : Color(hex: assigneeColor))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(event.startAt.shortTime)
                    if let loc = event.location {
                        Text("· \(loc)")
                    }
                    if event.isConflicting {
                        Text("· CONFLICT")
                            .fontWeight(.semibold)
                    }
                }
                .font(.system(size: 9))
                .foregroundColor(event.isConflicting ? Color.conflictText.opacity(0.8) : Color.textMuted)
            }

            Spacer()
        }
        .padding(8)
        .background(
            event.isConflicting
                ? Color.conflictBg
                : Color(hex: assigneeColor).opacity(0.08)
        )
        .cornerRadius(6)
    }
}
```

---

## 8. Component: OverdueAlertBanner

```swift
// Dashboard/Components/OverdueAlertBanner.swift
struct OverdueAlertBanner: View {
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            Text("🔴").font(.system(size: 14))
            Text("\(count) overdue task\(count == 1 ? "" : "s") need\(count == 1 ? "s" : "") attention")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.overdueText)
            Spacer()
            // Navigate to Tasks tab with overdue filter
            Text("View →")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#E24B4A"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.overdueBg)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#FECACA"), lineWidth: 1))
        .cornerRadius(8)
    }
}
```

---

## 9. Component: RecentTasksSection

```swift
// Dashboard/Components/RecentTasksSection.swift
struct RecentTasksSection: View {
    let tasks: [DashboardTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recently assigned")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.textPrimary)

            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    RecentTaskRow(task: task)
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
        }
    }
}

struct RecentTaskRow: View {
    let task: DashboardTask

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox — not interactive from dashboard (navigate to Tasks instead)
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.cardBorder, lineWidth: 2)
                .frame(width: 16, height: 16)

            // Assignee avatar
            if let color = task.assigneeColor, let name = task.assigneeName {
                AvatarView(name: name, color: color, size: 18)
            }

            Text(task.title)
                .font(.system(size: 12))
                .foregroundColor(task.isOverdue ? Color(hex: "#E24B4A") : Color.textPrimary)
                .lineLimit(1)

            Spacer()

            // Badge
            if task.isOverdue {
                Text("Overdue")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.overdueText)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.overdueBg)
                    .cornerRadius(4)
            } else if Calendar.current.isDateInToday(task.dueAt) {
                Text("Today")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.conflictText)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.conflictBg)
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(Divider().frame(maxWidth: .infinity), alignment: .bottom)
    }
}
```

---

## 10. Component: FamilyProgressSection

```swift
// Dashboard/Components/FamilyProgressSection.swift
struct FamilyProgressSection: View {
    let progress: [MemberProgress]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Family this week")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.textPrimary)

            VStack(spacing: 10) {
                ForEach(progress) { member in
                    MemberProgressRow(member: member)
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
        }
    }
}

struct MemberProgressRow: View {
    let member: MemberProgress

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                AvatarView(name: member.displayName, color: member.color, size: 20)
                Text(member.displayName)
                    .font(.system(size: 11))
                    .foregroundColor(Color.textPrimary)
                Spacer()
                Text("\(member.tasksCompleted)/\(member.tasksTotal)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: member.color))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.cardBorder)
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: member.color))
                        .frame(width: geo.size.width * member.progressFraction, height: 5)
                }
            }
            .frame(height: 5)
        }
    }
}
```

---

## 11. Component: ShoppingNudgeCard

```swift
// Dashboard/Components/ShoppingNudgeCard.swift
struct ShoppingNudgeCard: View {
    let nudge: ShoppingNudge

    private var lastUpdatedLabel: String {
        let days = Calendar.current.dateComponents([.day],
            from: nudge.lastUpdatedAt, to: Date()).day ?? 0
        if days == 0 { return "Updated today" }
        if days == 1 { return "Updated yesterday" }
        return "Last updated \(days) days ago"
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("🛒").font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(nudge.listName) — \(nudge.uncheckedCount) items to buy")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#14532D"))
                Text(lastUpdatedLabel)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#166534"))
            }
            Spacer()
            // Navigate to Shopping tab with this list selected
            Text("Go →")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#1D9E75"))
        }
        .padding(12)
        .background(Color(hex: "#F0FDF4"))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#BBF7D0"), lineWidth: 1))
        .cornerRadius(8)
    }
}
```

---

## 12. ChildDashboardView

**File:** `Dashboard/ChildDashboardView.swift`

```swift
struct ChildDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject var vm: DashboardViewModel

    var data: ChildDashboardResponse? { vm.childData }

    var body: some View {
        VStack(spacing: 0) {
            // Child header — points shown in header
            ChildDashboardHeader(
                profile:  data?.profile,
                onAvatarTap: { /* navigate to profile settings */ }
            )

            if vm.isLoading && data == nil {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let d = data {
                let isEmpty = d.todaysTasks.isEmpty && d.upcomingEvents.isEmpty

                ScrollView {
                    LazyVStack(spacing: 14) {

                        // 1. Stats card — always shown
                        ChildStatsCard(profile: d.profile, stats: d.stats)

                        // 2. Goal progress — if goal exists
                        if let goal = d.activeGoal {
                            ChildGoalCard(goal: goal)
                        }

                        // Empty welcome message when no tasks/events
                        if isEmpty {
                            ChildWelcomeCard(displayName: d.profile.displayName)
                        } else {
                            // 3. Today's tasks
                            if !d.todaysTasks.isEmpty {
                                ChildTasksSection(
                                    tasks: d.todaysTasks,
                                    onComplete: { task in
                                        Task { await vm.completeTask(task) }
                                    },
                                    completingIds: vm.completingTaskIds
                                )
                            }

                            // 4. Upcoming events
                            if !d.upcomingEvents.isEmpty {
                                ChildEventsSection(events: d.upcomingEvents)
                            }
                        }

                        // 5. Family members — always shown
                        FamilyMembersRow(members: d.familyMembers)
                    }
                    .padding(14)
                }
                .refreshable { await vm.load(role: "child") }
            }
        }
        // No FAB for children
    }
}
```

---

## 13. Component: ChildDashboardHeader

```swift
// Dashboard/Components/ChildDashboardHeader.swift
struct ChildDashboardHeader: View {
    let profile: DashboardProfile?
    let onAvatarTap: () -> Void

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = profile?.displayName ?? ""
        if hour < 12 { return "Good morning, \(name) ☀️" }
        if hour < 17 { return "Good afternoon, \(name) 🌤" }
        return "Good evening, \(name) 🌙"
    }

    var body: some View {
        ZStack {
            Color.appNavy
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(Date().dashboardDateLabel)
                        .font(.system(size: 9))
                        .foregroundColor(Color.appNavySub)
                }
                Spacer()
                // Points balance right-aligned
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(profile?.pointsBalance ?? 0)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("pts")
                        .font(.system(size: 8))
                        .foregroundColor(Color.appNavySub)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }
}
```

---

## 14. Component: ChildStatsCard

```swift
// Dashboard/Components/ChildStatsCard.swift
struct ChildStatsCard: View {
    let profile: DashboardProfile
    let stats:   ChildStats

    var body: some View {
        HStack(spacing: 0) {
            StatPill(
                value: "\(profile.pointsTotal)",
                label: "all-time pts",
                color: Color.memberAmber
            )
            Divider().frame(height: 40)
            StatPill(
                value: streakDisplay,
                label: streakLabel,
                color: streakColor
            )
            Divider().frame(height: 40)
            StatPill(
                value: "🥇 \(rankLabel(stats.weeklyRank))",
                label: "this week",
                color: Color.memberBlue
            )
        }
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
    }

    private var streakDisplay: String {
        switch profile.streakStatus {
        case "active": return "🔥 \(profile.streak)"
        case "grace":  return "🔸 \(profile.streak)"
        default:       return "—"
        }
    }

    private var streakLabel: String {
        switch profile.streakStatus {
        case "active": return "day streak"
        case "grace":  return "grace"
        default:       return "no streak"
        }
    }

    private var streakColor: Color {
        profile.streakStatus == "none" ? Color.textMuted : Color.memberAmber
    }

    private func rankLabel(_ rank: Int) -> String {
        switch rank {
        case 1: return "1st 🏆"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(rank)th"
        }
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(Color.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}
```

---

## 15. Component: FamilyMembersRow

```swift
// Dashboard/Components/FamilyMembersRow.swift
struct FamilyMembersRow: View {
    let members: [FamilyMemberRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Our family")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(members) { member in
                        FamilyMemberCard(member: member)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

struct FamilyMemberCard: View {
    let member: FamilyMemberRow

    var body: some View {
        VStack(spacing: 4) {
            AvatarView(
                name:     member.displayName,
                color:    member.color,
                size:     38,
                isActive: member.isSelf
            )

            Text(member.isSelf ? "You" : member.displayName)
                .font(.system(size: 9, weight: member.isSelf ? .bold : .regular))
                .foregroundColor(member.isSelf ? Color(hex: member.color) : Color.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: 48)

            // Line 2 — streak if active/grace, or "Parent" label
            if member.role == "parent" {
                Text("Parent")
                    .font(.system(size: 8))
                    .foregroundColor(Color.textMuted)
            } else {
                Text(member.streakDisplay)
                    .font(.system(size: 8, weight: member.streakStatus != "none" ? .semibold : .regular))
                    .foregroundColor(
                        member.streakStatus == "active" ? Color.memberAmber :
                        member.streakStatus == "grace"  ? Color.memberAmber :
                        Color.textMuted
                    )
            }
        }
        .frame(minWidth: 48)
    }
}
```

---

## 16. Component: ChildTasksSection

```swift
// Dashboard/Components/ChildTasksSection.swift
struct ChildTasksSection: View {
    let tasks:          [ChildTask]
    let onComplete:     (ChildTask) -> Void
    let completingIds:  Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My tasks today")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.textPrimary)

            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    ChildTaskRow(
                        task:         task,
                        isCompleting: completingIds.contains(task.id),
                        onTap: { if !task.isDone { onComplete(task) } }
                    )
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
        }
    }
}

struct ChildTaskRow: View {
    let task:         ChildTask
    let isCompleting: Bool
    let onTap:        () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(task.isDone ? Color(hex: "#1D9E75") : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(task.isDone ? Color(hex: "#1D9E75") : Color.cardBorder, lineWidth: 2)
                        )
                        .frame(width: 18, height: 18)

                    if isCompleting {
                        ProgressView().scaleEffect(0.5)
                    } else if task.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 13))
                .foregroundColor(
                    task.isDone    ? Color.textMuted :
                    task.isOverdue ? Color(hex: "#E24B4A") :
                    Color.textPrimary
                )
                .strikethrough(task.isDone, color: Color.textMuted)
                .lineLimit(1)

            Spacer()

            if task.isDone {
                Text("+\(task.points) pts")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "#1D9E75"))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.doneBg)
                    .cornerRadius(4)
            } else if task.isOverdue {
                Text("Overdue")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.overdueText)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.overdueBg)
                    .cornerRadius(4)
            } else if Calendar.current.isDateInToday(task.dueAt) {
                Text("Today")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.conflictText)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.conflictBg)
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(Divider().frame(maxWidth: .infinity), alignment: .bottom)
    }
}
```

---

## 17. Parent vs Child — Feature Matrix

| Feature | Parent | Child |
|---|---|---|
| Greeting header | ✅ with date | ✅ with date |
| Points in header | ❌ | ✅ (balance) |
| Avatar filter row | ✅ | ❌ |
| FAB | ✅ | ❌ |
| AI conflict card | ✅ (V1.5) | ❌ |
| 5-day schedule strip | ✅ all family | ❌ |
| Overdue alert | ✅ | ❌ |
| Recently assigned tasks | ✅ | ❌ |
| Family weekly progress | ✅ | ❌ |
| Shopping nudge | ✅ | ❌ |
| Pending approvals nudge | ✅ | ❌ |
| Stats card (pts/streak/rank) | ❌ | ✅ |
| Active goal progress | ❌ | ✅ |
| My tasks today (checkable) | ❌ | ✅ |
| My upcoming events | ❌ | ✅ |
| Family members row | ❌ | ✅ |
| Empty state — 3 CTAs | ✅ | ❌ |
| Empty state — welcome card | ❌ | ✅ |
