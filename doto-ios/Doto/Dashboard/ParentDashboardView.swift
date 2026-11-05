import SwiftUI

// Inline ShoppingNudgeCard to avoid compile order issues
struct ShoppingNudgeCard: View {
    let nudge: ShoppingNudge
    var onTap: () -> Void = {}

    private var lastUpdatedLabel: String {
        let days = Calendar.current.dateComponents([.day],
            from: nudge.lastUpdatedAt, to: Date()).day ?? 0
        if days == 0 { return "Updated today" }
        if days == 1 { return "Last updated 1 day ago" }
        return "Last updated \(days) days ago"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "cart")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.dashGreen)
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "#D6F2E0"))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(nudge.listName) — \(nudge.uncheckedCount) items to buy")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.dashNavy)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(lastUpdatedLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.dashSubtle)
                }
                Spacer(minLength: 8)
                Text("Go →")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.dashGreen)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .dashboardCard(radius: 12, fill: .dashGreenTint, border: .dashGreenBorder)
        }
        .buttonStyle(.plain)
    }
}

struct ParentDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject var vm: DashboardViewModel
    @Binding var selectedTab: DotoTab
    @State private var showFABSheet = false
    @State private var showAddEvent = false
    @State private var showAddTask = false
    @State private var showAddItem = false
    @State private var showSettings = false
    @State private var showFamilyManage = false
    @State private var selectedTask: DashboardTask? = nil
    @State private var showEditTask = false

    var data: ParentDashboardResponse? { vm.parentData }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DashboardBackground()

            VStack(spacing: 0) {
                DashboardHeader(
                    profile: data?.profile,
                    onAvatarTap: { showSettings = true }
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
                            onInvitePartner: { showFamilyManage = true }
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
                                    OverdueAlertBanner(count: d.overdueCount) {
                                        selectedTab = .tasks
                                    }
                                }

                                // 3. Today's tasks
                                if !d.recentTasks.isEmpty {
                                    TodaysTasksSection(
                                        tasks: d.recentTasks,
                                        onSeeAll: { selectedTab = .tasks },
                                        onTaskTap: { task in
                                            selectedTask = task
                                            showEditTask = true
                                        },
                                        onComplete: { task in
                                            Task { await vm.completeParentTask(task) }
                                        },
                                        completingIds: vm.completingParentTaskIds,
                                        lockedIds: vm.lockedTaskIds
                                    )
                                }

                                // 4. Family weekly progress
                                if !d.familyProgress.isEmpty {
                                    FamilyProgressSection(progress: d.familyProgress)
                                }

                                // 5. Shopping nudge
                                if let nudge = d.shoppingNudge {
                                    ShoppingNudgeCard(nudge: nudge) {
                                        selectedTab = .shopping
                                    }
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
                            .padding(.horizontal, 18)
                            .padding(.bottom, 80) // space for FAB
                        }
                        .refreshable { await vm.load(role: "parent") }
                    }
                }
            }

            // FAB
            fabButton
                .padding(.trailing, 20)
                .padding(.bottom, 16)
        }
        .sheet(isPresented: $showFABSheet) {
            FABBottomSheet(showAddEvent: $showAddEvent, showAddTask: $showAddTask, showAddItem: $showAddItem)
        }
        .sheet(isPresented: $showAddEvent) {
            AddEditEventView(event: nil)
                .onDisappear { Task { await vm.load(role: "parent") } }
        }
        .sheet(isPresented: $showAddItem) {
            // Dashboard FAB opens AddItemSheet with no pre-selected list
            // AddItemSheet will handle loading lists or show empty state
            AddItemSheet(availableLists: [], preselectedListId: nil, vm: ShoppingViewModel())
        }
        .sheet(isPresented: $showAddTask) {
            AddEditTaskView(task: nil)
        }
        .sheet(isPresented: $showEditTask) {
            if let task = selectedTask {
                AddEditTaskView(task: DotoTask(
                    id: task.id,
                    familyId: nil,
                    title: task.title,
                    notes: nil,
                    assignedTo: task.assignedTo,
                    priority: task.priority,
                    status: task.status,
                    points: task.points,
                    dueDate: task.dueDate,
                    repeatRule: task.repeatRule,
                    repeatDays: task.repeatDays,
                    repeatUntil: task.repeatUntil,
                    completedAt: nil,
                    seriesId: task.seriesId,
                    isSeriesParent: task.isSeriesParent,
                    isRecurringFlag: task.isRecurring,
                    createdBy: nil,
                    createdAt: nil,
                    updatedAt: nil
                ))
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showFamilyManage) {
            FamilyManageView()
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
                .background(Color.dashBlue)
                .clipShape(Circle())
                .shadow(color: Color.dashBlue.opacity(0.4), radius: 10, x: 0, y: 5)
        }
    }
}
