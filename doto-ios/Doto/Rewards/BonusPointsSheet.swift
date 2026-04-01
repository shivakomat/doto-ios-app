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
        VStack(alignment: .leading, spacing: 16) {
            Capsule().fill(Color.cardBorder)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text("Give bonus points")
                .font(.system(size: 17, weight: .semibold))
                .padding(.horizontal, 20)

            if allChildren.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("For").font(.system(size: 12)).foregroundColor(.textMuted)
                        .padding(.horizontal, 20)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(allChildren) { child in
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
                        .padding(.horizontal, 20)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Points").font(.system(size: 12)).foregroundColor(.textMuted)
                    .padding(.horizontal, 20)

                HStack(spacing: 16) {
                    Button { if amount > 1 { amount -= 1 } } label: {
                        Image(systemName: "minus")
                            .frame(width: 32, height: 32)
                            .background(Color.screenBg)
                            .cornerRadius(8)
                    }
                    Text("\(amount)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.memberBlue)
                        .frame(minWidth: 60, alignment: .center)
                    Button { if amount < 500 { amount += 1 } } label: {
                        Image(systemName: "plus")
                            .frame(width: 32, height: 32)
                            .background(Color.screenBg)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        Button("+\(preset)") { amount = preset }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(amount == preset ? Color.memberBlue : Color(hex: "#EFF6FF"))
                            .foregroundColor(amount == preset ? .white : .memberBlue)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Note (shown to \(selectedName))")
                    .font(.system(size: 12)).foregroundColor(.textMuted)
                    .padding(.horizontal, 20)
                TextField("What did they do well?", text: $note)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder))
                    .padding(.horizontal, 20)
            }

            Button {
                onSubmit(selectedMemberId, amount, note.isEmpty ? nil : note)
                dismiss()
            } label: {
                Text("Give \(amount) bonus points to \(selectedName)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.memberBlue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.white)
    }
}
