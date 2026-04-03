import SwiftUI

// Inline ShoppingNudgeCard to avoid compile order issues
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

struct ParentDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject var vm: DashboardViewModel
    @State private var showFABSheet = false
    @State private var showAddEvent = false
    @State private var showAddTask = false
    @State private var showSettings = false
    @State private var selectedMemberId: String? = nil

    var data: ParentDashboardResponse? { vm.parentData }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Dark navy header
                ParentDashboardHeader(
                    profile: data?.profile,
                    members: data?.family.members ?? [],
                    onAvatarTap: { showSettings = true },
                    onMemberTap: { id in
                        selectedMemberId = selectedMemberId == id ? nil : id
                    },
                    selectedMemberId: selectedMemberId
                )

                if vm.isLoading && data == nil {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let d = data {
                    // Empty state — no events AND no recent tasks
                    let noContent = d.upcomingEvents.days.allSatisfy({ $0.events.isEmpty }) &&
                                    d.recentTasks.isEmpty &&
                                    d.familyProgress.isEmpty

                    if noContent {
                        ParentEmptyDashboard(
                            onAddEvent: { showAddEvent = true },
                            onAddTask: { showAddTask = true },
                            onInvitePartner: { /* Navigate to family management */ }
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                // 1. 5-day schedule strip
                                FiveDayStripView(
                                    days: d.upcomingEvents.days,
                                    selectedIndex: $vm.selectedDayIndex,
                                    members: d.family.members
                                )

                                // 2. Overdue alert
                                if d.overdueCount > 0 {
                                    OverdueAlertBanner(count: d.overdueCount)
                                }

                                // 3. Recently assigned tasks
                                if !d.recentTasks.isEmpty {
                                    RecentTasksSection(tasks: d.recentTasks)
                                }

                                // 4. Family weekly progress
                                if !d.familyProgress.isEmpty {
                                    FamilyProgressSection(progress: d.familyProgress)
                                }

                                // 5. Shopping nudge
                                if let nudge = d.shoppingNudge {
                                    ShoppingNudgeCard(nudge: nudge)
                                }

                                // 6. Pending reward approvals
                                ForEach(d.pendingApprovals) { approval in
                                    PendingApprovalNudge(
                                        approval: approval,
                                        onApprove: { /* Handle approval */ },
                                        onDeny: { /* Handle denial */ }
                                    )
                                }
                            }
                            .padding(14)
                            .padding(.bottom, 80) // space for FAB
                        }
                        .refreshable { await vm.load(role: "parent") }
                    }
                }
            }

            // FAB
            fabButton
                .padding(20)
        }
        .sheet(isPresented: $showFABSheet) {
            FABBottomSheet(showAddEvent: $showAddEvent, showAddTask: $showAddTask, showAddItem: .constant(false))
        }
        .sheet(isPresented: $showAddEvent) {
            Text("Add Event View") // Replace with actual AddEditEventView
        }
        .sheet(isPresented: $showAddTask) {
            Text("Add Task View") // Replace with actual AddEditTaskView
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var fabButton: some View {
        Button {
            showFABSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.memberBlue)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
}
