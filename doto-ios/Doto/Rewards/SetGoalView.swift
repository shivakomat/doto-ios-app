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
            AuthScreen(
                title: "Set a goal",
                subtitle: "You have \(memberBalance) pts to work with."
            ) {
                VStack(alignment: .leading, spacing: 22) {

                    // Tier 1 — Previous goals
                    if !previousGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            DashboardSectionHeader(title: "Your previous goals")
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
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    // Tier 2 — Family catalog
                    if !vm.catalog.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            DashboardSectionHeader(title: "Family catalog")
                            VStack(spacing: 0) {
                                ForEach(Array(vm.catalog.enumerated()), id: \.element.id) { idx, item in
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
                                    .overlay(alignment: .bottom) {
                                        if idx < vm.catalog.count - 1 {
                                            Rectangle().fill(Color.dashCardBorder).frame(height: 1).padding(.horizontal, 14)
                                        }
                                    }
                                }
                            }
                            .dashboardCard()
                        }
                    }

                    // Tier 3 — Custom
                    VStack(alignment: .leading, spacing: 12) {
                        DashboardSectionHeader(title: "Or create your own")

                        AuthTextField(label: "What do you want to earn?", text: $customTitle)

                        HStack {
                            Text("Points needed")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.dashNavy)
                            Spacer()
                            Stepper("\(customCost)", value: $customCost, in: 5...500, step: 5)
                                .font(.system(size: 15, weight: .semibold))
                                .fixedSize()
                        }
                        .padding(14)
                        .dashboardCard(radius: 14)

                        if let error = vm.errorMessage {
                            AuthMessage(text: error)
                        }

                        PrimaryButton(title: isSubmitting ? "Setting goal..." : "Set this as my goal", isLoading: isSubmitting) {
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
                        }
                        .disabled(customTitle.isEmpty || isSubmitting || vm.isLoading)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .tint(.dashBlue)
    }
}
