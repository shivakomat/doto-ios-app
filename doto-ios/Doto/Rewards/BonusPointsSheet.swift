import SwiftUI

struct BonusPointsSheet: View {
    let targetDisplayName: String
    let targetMemberId: String
    let allChildren: [LeaderboardEntry]
    let onSubmit: (String, Int, String?) -> Void

    @State private var selectedMemberId: String
    @State private var amount = 25
    @State private var note = ""
    @Environment(\.dismiss) private var dismiss

    private let presets = [5, 10, 25, 50]

    init(targetDisplayName: String, targetMemberId: String,
         allChildren: [LeaderboardEntry],
         onSubmit: @escaping (String, Int, String?) -> Void) {
        self.targetDisplayName = targetDisplayName
        self.targetMemberId = targetMemberId
        self.allChildren = allChildren
        self.onSubmit = onSubmit
        _selectedMemberId = State(initialValue: targetMemberId)
    }

    private var selectedName: String {
        allChildren.first { $0.memberId == selectedMemberId }?.displayName ?? targetDisplayName
    }

    var body: some View {
        ZStack {
            DashboardBackground(showLandscape: false)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Capsule().fill(Color.dashCardBorder)
                        .frame(width: 36, height: 4)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    Text("Give bonus points")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.dashNavy)

                    if allChildren.count > 1 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("For")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.dashNavy)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(allChildren) { child in
                                        let selected = selectedMemberId == child.memberId
                                        VStack(spacing: 6) {
                                            AvatarView(
                                                name: child.displayName,
                                                color: child.color,
                                                size: 40,
                                                isActive: selected
                                            )
                                            Text(child.displayName)
                                                .font(.system(size: 12, weight: selected ? .semibold : .regular))
                                                .foregroundColor(selected ? .dashBlue : .dashSubtle)
                                        }
                                        .padding(.vertical, 10)
                                        .frame(width: 80)
                                        .dashboardCard(radius: 14,
                                                       fill: selected ? .dashBlueTint : .white,
                                                       border: selected ? .dashBlue : .dashCardBorder)
                                        .onTapGesture { selectedMemberId = child.memberId }
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Points")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.dashNavy)

                        HStack(spacing: 20) {
                            stepButton("minus") { if amount > 1 { amount -= 1 } }
                            Text("\(amount)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.dashBlue)
                                .frame(minWidth: 90)
                            stepButton("plus") { if amount < 500 { amount += 1 } }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .dashboardCard(radius: 16)

                        HStack(spacing: 8) {
                            ForEach(presets, id: \.self) { preset in
                                Button("+\(preset)") { amount = preset }
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(amount == preset ? Color.dashBlue : Color.dashBlueTint)
                                    .foregroundColor(amount == preset ? .white : .dashBlue)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    AuthTextField(label: "Note (shown to \(selectedName))", text: $note,
                                  placeholder: "What did they do well?")

                    PrimaryButton(title: "Give \(amount) bonus points to \(selectedName)") {
                        onSubmit(selectedMemberId, amount, note.isEmpty ? nil : note)
                        dismiss()
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 24)
            }
        }
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.dashBlue)
                .frame(width: 44, height: 44)
                .background(Color.dashBlueTint)
                .clipShape(Circle())
        }
    }
}
