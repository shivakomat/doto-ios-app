import SwiftUI

struct FamilyPreviewView: View {
    let preview: FamilyPreview
    @State private var selectedRole = "parent"
    @State private var navigateToRegister = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text(preview.familyName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                Text("\(preview.memberCount) member\(preview.memberCount == 1 ? "" : "s") already")
                    .font(.system(size: 14))
                    .foregroundColor(.textMuted)
            }
            .padding(.top, 24)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("I am a...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)

                HStack(spacing: 12) {
                    RoleCard(
                        emoji: "👨‍👩‍👧",
                        label: "Parent",
                        isSelected: selectedRole == "parent"
                    ) { selectedRole = "parent" }

                    RoleCard(
                        emoji: "👦",
                        label: "Child / Teen",
                        isSelected: selectedRole == "child"
                    ) { selectedRole = "child" }
                }
            }

            NavigationLink(destination: RegisterView(
                path: .joinFamily(inviteCode: preview.inviteCode, role: selectedRole)
            )) {
                Text("Create my account →")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 24)
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("You're joining...")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct RoleCard: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(emoji).font(.system(size: 28))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .memberBlue : .textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color(hex: "#EFF6FF") : Color(hex: "#F8FAFC"))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color.memberBlue : Color(hex: "#E2E8F0"),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
