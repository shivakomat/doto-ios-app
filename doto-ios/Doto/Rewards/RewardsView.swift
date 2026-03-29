import SwiftUI

struct RewardsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = RewardsViewModel()
    @State private var showSetGoal = false

    private var isParent: Bool { authVM.currentProfile?.isParent == true }
    private let medals = ["🥇", "🥈", "🥉"]

    var body: some View {
        VStack(spacing: 0) {
            DotoNavHeader(title: "Rewards")

            if vm.isLoading && vm.rewards.isEmpty {
                LoadingView()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        leaderboardSection
                        goalsSection
                        streaksSection
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
                .refreshable { await vm.load() }
            }
        }
        .background(Color.screenBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await vm.load() }
        .sheet(isPresented: $showSetGoal, onDismiss: { Task { await vm.load() } }) {
            SetGoalSheet(vm: vm)
        }
        .alert("Something went wrong",
               isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This week's leaderboard 🏆")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)

            VStack(spacing: 0) {
                let board = vm.leaderboard()
                ForEach(Array(board.enumerated()), id: \.element.profile.id) { idx, entry in
                    HStack(spacing: 10) {
                        Text(idx < medals.count ? medals[idx] : "")
                            .font(.system(size: 16))
                            .frame(width: 22)
                        AvatarView(name: entry.profile.displayName, color: entry.profile.color, size: 22)
                        Text(entry.profile.displayName)
                            .font(.system(size: 13))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("\(entry.points) pts")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(idx == 0 ? .memberBlue : .textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    if idx < board.count - 1 { Divider().padding(.leading, 14) }
                }
            }
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder, lineWidth: 1))
            .cornerRadius(8)
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(vm.activeGoals) { reward in
                goalCard(reward)
            }

            Button {
                showSetGoal = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Set a goal")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.memberBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: "#EFF6FF"))
                .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    private func goalCard(_ reward: Reward) -> some View {
        let member = vm.members.first { $0.id == reward.memberId }
        let allTimePoints = member?.points ?? 0
        let progress = min(1.0, Double(allTimePoints) / Double(max(1, reward.pointsCost)))
        let toGo = max(0, reward.pointsCost - allTimePoints)
        let canClaim = allTimePoints >= reward.pointsCost && reward.status == "active"
        let isPending = reward.status == "pending_approval"

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(member?.displayName ?? "")'s goal")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.conflictText)
                Spacer()
                Text("\(reward.pointsCost) pts")
                    .font(.system(size: 11))
                    .foregroundColor(.conflictText)
            }

            Text(reward.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#FAC775").opacity(0.4))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(canClaim ? Color.doneText : Color(hex: member?.color ?? "#185FA5"))
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(allTimePoints) / \(reward.pointsCost) pts · \(toGo) to go")
                    .font(.system(size: 11))
                    .foregroundColor(.conflictText)
                Spacer()

                if isPending && isParent {
                    HStack(spacing: 8) {
                        Button {
                            Task { await vm.approveReward(reward) }
                        } label: {
                            Text("Approve ✓")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.doneText)
                                .cornerRadius(6)
                        }
                        Button {
                            Task { await vm.declineReward(reward) }
                        } label: {
                            Text("Decline")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.overdueText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.overdueBg)
                                .cornerRadius(6)
                        }
                    }
                } else if isPending {
                    Text("Pending...")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.conflictText)
                } else if canClaim && reward.memberId == authVM.currentProfile?.id {
                    Button {
                        Task { await vm.requestReward(reward) }
                    } label: {
                        Text("Claim! 🎉")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.doneText)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(hex: "#FAEEDA"))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#FAC775"), lineWidth: 1))
        .cornerRadius(8)
    }

    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Streaks 🔥")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)

            VStack(spacing: 0) {
                let streakMembers = vm.members.filter { !$0.isParent }
                ForEach(Array(streakMembers.enumerated()), id: \.element.id) { idx, member in
                    HStack(spacing: 10) {
                        AvatarView(name: member.displayName, color: member.color, size: 22)
                        Text(member.displayName)
                            .font(.system(size: 13))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("🔥 \(member.streak ?? 0) days")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor((member.streak ?? 0) > 0 ? Color.memberAmber : .textMuted)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    if idx < streakMembers.count - 1 { Divider().padding(.leading, 14) }
                }

                if vm.members.filter({ !$0.isParent }).isEmpty {
                    Text("No streaks yet")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                        .padding()
                }
            }
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder, lineWidth: 1))
            .cornerRadius(8)
        }
    }
}

struct SetGoalSheet: View {
    @ObservedObject var vm: RewardsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var pointsCost = 50
    @State private var selectedMemberId = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Reward title", text: $title)
                }
                Section(header: Text("Points cost")) {
                    Stepper("\(pointsCost) pts", value: $pointsCost, in: 10...1000, step: 10)
                }
                if vm.members.contains(where: { !$0.isParent }) {
                    Section(header: Text("For")) {
                        Picker("Member", selection: $selectedMemberId) {
                            ForEach(vm.members.filter { !$0.isParent }) { m in
                                Text(m.displayName).tag(m.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Set a goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading { ProgressView() }
                    else {
                        Button("Save") {
                            Task {
                                isLoading = true
                                let memberId = selectedMemberId.isEmpty ? (authVM.currentProfile?.id ?? "") : selectedMemberId
                                await vm.createReward(title: title, pointsCost: pointsCost, memberId: memberId)
                                isLoading = false
                                dismiss()
                            }
                        }
                        .disabled(title.isEmpty)
                    }
                }
            }
            .onAppear {
                selectedMemberId = vm.members.first(where: { !$0.isParent })?.id
                    ?? authVM.currentProfile?.id
                    ?? ""
            }
        }
    }
}
