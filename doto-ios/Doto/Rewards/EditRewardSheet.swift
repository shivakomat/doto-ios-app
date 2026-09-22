import SwiftUI

struct EditRewardSheet: View {
    let reward: Reward
    @ObservedObject var vm: RewardsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var emoji: String
    @State private var pointsCost: Int
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(reward: Reward, vm: RewardsViewModel) {
        self.reward = reward
        self.vm = vm
        _title = State(initialValue: reward.title)
        _emoji = State(initialValue: reward.emoji ?? "")
        _pointsCost = State(initialValue: reward.pointsCost)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    HStack {
                        TextField("Emoji", text: $emoji)
                            .frame(width: 44)
                        TextField("Reward title", text: $title)
                    }
                    Stepper("Points: \(pointsCost)",
                            value: $pointsCost, in: 5...500, step: 5)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
                    .foregroundColor(.textMuted)
            )

            VStack(spacing: 10) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#E24B4A"))
                        .multilineTextAlignment(.center)
                }
                Button {
                    Task { await saveEdit() }
                } label: {
                    Text(isSubmitting ? "Saving..." : "Save Changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func saveEdit() async {
        isSubmitting = true; defer { isSubmitting = false }
        struct EditBody: Encodable {
            let title: String; let emoji: String?; let pointsCost: Int
        }
        do {
            let _: Reward = try await APIClient.shared.put(
                "/rewards/\(reward.id)",
                body: EditBody(
                    title: title.trimmingCharacters(in: .whitespaces),
                    emoji: emoji.isEmpty ? nil : emoji,
                    pointsCost: pointsCost
                )
            )
            await vm.loadRewards()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
