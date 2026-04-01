import SwiftUI

struct SetGoalView: View {
    let memberId: String
    let memberBalance: Int
    let previousGoals: [Reward]
    @ObservedObject var vm: RewardsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var customTitle = ""
    @State private var customCost = 100
    @State private var isSubmitting = false
    @State private var selectedMemberId: String = ""

    private var effectiveMemberId: String {
        selectedMemberId.isEmpty ? memberId : selectedMemberId
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Tier 1 — Previous goals
                    if !previousGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("Your previous goals")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(previousGoals) { goal in
                                        PreviousGoalChip(goal: goal) {
                                            Task {
                                                await vm.createReward(
                                                    memberId: effectiveMemberId,
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
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Tier 2 — Family catalog
                    if !vm.catalog.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("Family catalog")
                            VStack(spacing: 1) {
                                ForEach(vm.catalog) { item in
                                    CatalogItemRow(item: item, memberBalance: memberBalance) {
                                        Task {
                                            await vm.createReward(
                                                memberId: effectiveMemberId,
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
                        sectionHeader("Or create your own")
                        VStack(spacing: 10) {
                            TextField("What do you want to earn?", text: $customTitle)
                                .font(.system(size: 14))
                                .padding(12)
                                .background(Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder))

                            HStack {
                                Text("Points needed:")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Stepper("\(customCost)", value: $customCost, in: 5...500, step: 5)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding(12)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder))

                            // Member picker for parents
                            if memberId.isEmpty {
                                memberPicker
                            }

                            Button {
                                guard !customTitle.isEmpty else { return }
                                isSubmitting = true
                                Task {
                                    await vm.createReward(
                                        memberId: effectiveMemberId,
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
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.memberBlue)
                                    .cornerRadius(10)
                            }
                            .disabled(customTitle.isEmpty || isSubmitting)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.screenBg)
            .navigationTitle("Set a goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Text("\(memberBalance) pts")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
            }
            .onAppear {
                if memberId.isEmpty {
                    selectedMemberId = vm.leaderboard?.entries.first(where: { $0.role == "child" })?.memberId ?? ""
                }
            }
        }
    }

    @ViewBuilder
    private var memberPicker: some View {
        let children = vm.leaderboard?.entries.filter { $0.role == "child" } ?? []
        if children.count > 1 {
            VStack(alignment: .leading, spacing: 6) {
                Text("For").font(.system(size: 12)).foregroundColor(.textMuted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(children) { child in
                            VStack(spacing: 4) {
                                AvatarView(
                                    name: child.displayName,
                                    color: child.color,
                                    size: 32,
                                    isActive: selectedMemberId == child.memberId
                                )
                                Text(child.displayName).font(.system(size: 9))
                                    .foregroundColor(selectedMemberId == child.memberId
                                        ? .memberBlue : .textMuted)
                            }
                            .onTapGesture { selectedMemberId = child.memberId }
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.textMuted)
            .textCase(.uppercase)
    }
}
