import SwiftUI

struct RewardsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = RewardsViewModel()
    @State private var showSetGoal = false
    @State private var showHistory = false

    private var isParent: Bool { authVM.currentProfile?.isParent == true }
    private var currentId: String? { authVM.currentProfile?.id }

    var body: some View {
        VStack(spacing: 0) {
            if isParent {
                DotoNavHeader(title: "Rewards", trailing: {
                    AnyView(NavAddButton(label: "Add Goal") { showSetGoal = true })
                })
            } else {
                DotoNavHeader(title: "Rewards", trailing: {
                    AnyView(
                        Text("\(authVM.currentProfile?.pointsBalance ?? 0)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        + Text("\npts to spend")
                            .font(.system(size: 9))
                            .foregroundColor(.appNavySub)
                    )
                })
            }

            if vm.isLoading && vm.leaderboard == nil {
                LoadingView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if isParent { parentContent } else { childContent }
                    }
                    .padding(14)
                    .padding(.bottom, 40)
                }
                .refreshable { await vm.loadAll() }
            }
        }
        .background(Color.screenBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await vm.loadAll() }
        .sheet(isPresented: $showSetGoal, onDismiss: { Task { await vm.loadRewards() } }) {
            if let profile = authVM.currentProfile {
                SetGoalView(
                    memberId: isParent ? "" : profile.id,
                    memberBalance: profile.pointsBalance,
                    previousGoals: vm.rewards.filter { $0.memberId == profile.id && $0.status == "redeemed" },
                    vm: vm
                )
            }
        }
        .sheet(isPresented: $vm.showBonusSheet) {
            if let targetId = vm.bonusTargetMemberId,
               let entry = vm.leaderboard?.entries.first(where: { $0.memberId == targetId }) {
                let children = vm.leaderboard?.entries.filter { $0.role == "child" } ?? []
                BonusPointsSheet(
                    targetDisplayName: entry.displayName,
                    targetMemberId: entry.memberId,
                    allChildren: children,
                    onSubmit: { memberId, amount, note in
                        Task { await vm.giveBonusPoints(toMemberId: memberId, amount: amount, note: note) }
                    }
                )
            }
        }
        .sheet(item: Binding(
            get: { vm.pendingMilestone.map { MilestoneWrapper(value: $0) } },
            set: { _ in vm.pendingMilestone = nil }
        )) { wrapper in
            MilestoneCelebrationView(milestoneValue: wrapper.value) {
                vm.pendingMilestone = nil
            }
        }
        .sheet(isPresented: $showHistory) {
            if let profile = authVM.currentProfile {
                PointsHistoryView(memberId: profile.id, displayName: profile.displayName)
            }
        }
        .alert("Something went wrong",
               isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Parent Content

    @ViewBuilder
    private var parentContent: some View {
        if let lb = vm.leaderboard {
            LeaderboardCard(leaderboard: lb, currentProfileId: currentId) { entry in
                if entry.role == "child" {
                    vm.bonusTargetMemberId = entry.memberId
                    vm.showBonusSheet = true
                }
            }
        }

        if !vm.pendingApprovals.isEmpty {
            PendingApprovalsSection(
                rewards: vm.pendingApprovals,
                leaderboard: vm.leaderboard,
                onApprove: { r in Task { await vm.approveReward(r) } },
                onDecline: { r in Task { await vm.declineReward(r) } }
            )
        }

        if let goal = vm.familyGoal {
            FamilyGoalCard(goal: goal)
        }

        GoalsSection(
            rewards: vm.activeGoals,
            leaderboard: vm.leaderboard,
            isParent: true,
            currentProfileId: currentId,
            onRequest: { r in Task { await vm.requestReward(r) } }
        )

        streaksSection
    }

    // MARK: - Child Content

    @ViewBuilder
    private var childContent: some View {
        if let profile = authVM.currentProfile {
            childBalanceCard(profile)
        }

        childGoalsSection

        if let lb = vm.leaderboard {
            LeaderboardCard(leaderboard: lb, currentProfileId: currentId)
        }

        Button { showHistory = true } label: {
            Text("View my points history →")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.memberBlue)
        }
    }

    // MARK: - Child Balance Card

    private func childBalanceCard(_ profile: Profile) -> some View {
        let rank = vm.leaderboard?.entries.firstIndex(where: { $0.memberId == profile.id })
            .map { $0 + 1 }

        return VStack(spacing: 12) {
            Text("ALL-TIME EARNED")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.textMuted)
            Text("\(profile.pointsTotal)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.memberBlue)
            Text("points")
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)

            HStack(spacing: 0) {
                statColumn(value: "\(profile.pointsBalance)", label: "to spend")
                Divider().frame(height: 30)
                statColumn(value: "\(profile.streakEmoji) \(profile.streak ?? 0)", label: "streak")
                Divider().frame(height: 30)
                statColumn(value: rank.map { "🥇 #\($0)" } ?? "—", label: "rank")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
        .cornerRadius(12)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Child Goals

    private var childGoalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("My Goals")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Button("+ Goal") { showSetGoal = true }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.memberBlue)
            }

            let myRewards = vm.activeGoals.filter { $0.memberId == currentId }
            if myRewards.isEmpty {
                Text("No goals yet — set one!")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                let balance = authVM.currentProfile?.pointsBalance ?? 0
                let color = authVM.currentProfile?.color ?? "#185FA5"
                ForEach(myRewards) { reward in
                    GoalCard(
                        reward: reward,
                        balance: balance,
                        memberColor: color,
                        isOwner: true,
                        onRequest: { Task { await vm.requestReward(reward) } }
                    )
                }
            }
        }
    }

    // MARK: - Streaks

    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Streaks 🔥")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)

            VStack(spacing: 0) {
                let childEntries = vm.leaderboard?.entries.filter { $0.role == "child" } ?? []
                if childEntries.isEmpty {
                    Text("No streaks yet")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                        .padding()
                } else {
                    ForEach(Array(childEntries.enumerated()), id: \.element.id) { idx, entry in
                        StreakRowView(entry: entry)
                            .padding(.horizontal, 14)
                        if idx < childEntries.count - 1 {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
            }
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder, lineWidth: 1))
            .cornerRadius(8)
        }
    }
}
