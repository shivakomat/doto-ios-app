import SwiftUI

struct SetGoalView: View {
    let memberBalance: Int
    let previousGoals: [Reward]
    @ObservedObject var vm: RewardsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var customTitle = ""
    @State private var customCost = 100
    @State private var isSubmitting = false

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

                            if let error = vm.errorMessage {
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#E24B4A"))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }

                            Button {
                                guard !customTitle.isEmpty else { return }
                                isSubmitting = true
                                Task {
                                    await vm.createReward(
                                        title: customTitle,
                                        emoji: nil,
                                        pointsCost: customCost,
                                        catalogItemId: nil
                                    )
                                    isSubmitting = false
                                    if vm.errorMessage == nil {
                                        dismiss()
                                    }
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
                            .disabled(customTitle.isEmpty || isSubmitting || vm.isLoading)
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
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.textMuted)
            .textCase(.uppercase)
    }
}
