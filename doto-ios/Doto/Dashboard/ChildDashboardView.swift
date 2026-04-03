import SwiftUI

struct ChildDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject var vm: DashboardViewModel
    @State private var showSettings = false

    var data: ChildDashboardResponse? { vm.childData }

    var body: some View {
        VStack(spacing: 0) {
            // Child header — points shown in header
            ChildDashboardHeader(
                profile: data?.profile,
                onAvatarTap: { showSettings = true }
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
        .sheet(isPresented: $showSettings) {
            ChildSettingsView()
        }
    }
}
