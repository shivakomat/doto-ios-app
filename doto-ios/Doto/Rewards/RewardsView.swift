import SwiftUI

enum RewardsTab: String, CaseIterable, Hashable {
    case thisWeek = "This Week"
    case streaks  = "Streaks"
    case catalog  = "Catalog"
}

struct RewardsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm: RewardsViewModel
    @State private var tab: RewardsTab = .thisWeek
    @State private var showSetGoal = false
    @State private var showHistory = false
    @State private var showCatalogForm = false
    @State private var editingCatalogItem: RewardCatalogItem?

    init(vm: RewardsViewModel = RewardsViewModel(), initialTab: RewardsTab = .thisWeek) {
        _vm = StateObject(wrappedValue: vm)
        _tab = State(initialValue: initialTab)
    }

    private var isParent: Bool { authVM.currentProfile?.isParent == true }
    private var currentId: String? { authVM.currentProfile?.id }

    private var streakEntries: [LeaderboardEntry] {
        let entries = vm.leaderboard?.entries ?? []
        return isParent ? entries.filter { $0.role == "child" } : entries.filter { $0.memberId == currentId }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DashboardBackground()

            VStack(spacing: 0) {
                ScreenTitleBar(title: "Rewards", subtitle: "Motivate. Celebrate. Build habits.") {
                    if isParent {
                        DashboardAddButton(title: "Add Goal") { showSetGoal = true }
                    } else {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(authVM.currentProfile?.pointsBalance ?? 0)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.dashBlue)
                            Text("pts to spend")
                                .font(.system(size: 11))
                                .foregroundColor(.dashSubtle)
                        }
                    }
                }

                DashboardSegmented(options: RewardsTab.allCases, title: { $0.rawValue }, selection: $tab)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)

                if vm.isLoading && vm.leaderboard == nil {
                    LoadingView()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            switch tab {
                            case .thisWeek: if isParent { parentContent } else { childContent }
                            case .streaks:  StreaksListCard(entries: streakEntries)
                            case .catalog:  catalogSection(style: .full)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 90)
                    }
                    .refreshable { await vm.loadAll() }
                }
            }

            // FAB for adding goals (parent only)
            if isParent {
                Button {
                    showSetGoal = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.dashBlue)
                        .clipShape(Circle())
                        .shadow(color: Color.dashBlue.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
        .task { await vm.loadAll() }
        .sheet(isPresented: $showSetGoal, onDismiss: { Task { await vm.loadRewards() } }) {
            if let profile = authVM.currentProfile {
                SetGoalView(
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
        .sheet(item: $vm.editingReward) { reward in
            EditRewardSheet(reward: reward, vm: vm)
        }
        .sheet(isPresented: $showCatalogForm, onDismiss: { editingCatalogItem = nil }) {
            RewardCatalogFormView(editingItem: editingCatalogItem) { category, title, cost, description in
                Task {
                    if let editing = editingCatalogItem {
                        await vm.updateCatalogItem(id: editing.id, category: category, title: title, cost: cost, description: description)
                    } else {
                        await vm.addCatalogItem(category: category, title: title, cost: cost, description: description)
                    }
                    showCatalogForm = false
                }
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

        StreaksSummaryCard(entries: streakEntries) { tab = .streaks }

        GoalsSection(
            familyGoal: vm.familyGoal,
            rewards: vm.activeGoals,
            leaderboard: vm.leaderboard,
            isParent: true,
            currentProfileId: currentId,
            onRequest: { r in Task { await vm.requestReward(r) } },
            onEdit: { r in vm.editingReward = r },
            onDelete: { r in Task { await vm.deleteReward(r) } }
        )

        catalogSection(style: .preview)
    }

    // MARK: - Child Content

    @ViewBuilder
    private var childContent: some View {
        if let profile = authVM.currentProfile {
            childBalanceCard(profile)
        }

        if let lb = vm.leaderboard {
            LeaderboardCard(leaderboard: lb, currentProfileId: currentId)
        }

        StreaksSummaryCard(entries: streakEntries) { tab = .streaks }

        childGoalsSection

        catalogSection(style: .preview)

        Button { showHistory = true } label: {
            Text("View my points history →")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.dashBlue)
        }
    }

    // MARK: - Child Balance Card

    private func childBalanceCard(_ profile: Profile) -> some View {
        let rank = vm.leaderboard?.entries.firstIndex(where: { $0.memberId == profile.id })
            .map { $0 + 1 }

        return VStack(spacing: 12) {
            Text("ALL-TIME EARNED")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.dashSubtle)
            Text("\(profile.pointsTotal)")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(.dashBlue)
            Text("points")
                .font(.system(size: 13))
                .foregroundColor(.dashSubtle)

            HStack(spacing: 0) {
                statColumn(value: "\(profile.pointsBalance)", label: "to spend")
                Rectangle().fill(Color.dashCardBorder).frame(width: 1, height: 30)
                statColumn(value: "\(profile.streakEmoji) \(profile.streak ?? 0)", label: "streak")
                Rectangle().fill(Color.dashCardBorder).frame(width: 1, height: 30)
                statColumn(value: rank.map { "🥇 #\($0)" } ?? "—", label: "rank")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .dashboardCard(radius: 16)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.dashNavy)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.dashSubtle)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Child Goals

    private var childGoalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashboardSectionHeader(title: "My Goals", actionTitle: "+ Goal") { showSetGoal = true }

            let myRewards = vm.activeGoals.filter { $0.memberId == nil || $0.memberId == currentId }
            if myRewards.isEmpty {
                Text("No goals yet — set one!")
                    .font(.system(size: 14))
                    .foregroundColor(.dashSubtle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .dashboardCard()
            } else {
                let balance = authVM.currentProfile?.pointsBalance ?? 0
                ForEach(Array(myRewards.enumerated()), id: \.element.id) { idx, reward in
                    GoalCard(
                        reward: reward,
                        balance: balance,
                        accentIndex: idx,
                        isOwner: true,
                        isParent: false,
                        onRequest: { Task { await vm.requestReward(reward) } },
                        onEdit: nil,
                        onDelete: nil
                    )
                }
            }
        }
    }

    // MARK: - Reward Catalog

    private func catalogSection(style: RewardCatalogGridView.Style) -> some View {
        RewardCatalogGridView(
            items: vm.catalog,
            isParent: isParent,
            memberBalance: authVM.currentProfile?.pointsBalance ?? 0,
            style: style,
            onAdd: {
                editingCatalogItem = nil
                showCatalogForm = true
            },
            onSeeAll: { tab = .catalog },
            onTapItem: { item in
                if isParent {
                    editingCatalogItem = item
                    showCatalogForm = true
                } else if currentId != nil {
                    Task {
                        await vm.createReward(
                            title: item.title,
                            emoji: item.emoji,
                            pointsCost: item.pointsCost,
                            catalogItemId: item.id
                        )
                    }
                }
            },
            onDeleteItem: { item in
                Task { await vm.deleteCatalogItem(item) }
            }
        )
    }
}
