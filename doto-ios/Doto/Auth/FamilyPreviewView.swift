import SwiftUI

struct FamilyPreviewView: View {
    let preview: FamilyPreview
    @State private var selectedRole = "parent"
    @State private var navigateToRegister = false
    @State private var navigateToClaim = false
    @StateObject private var claimVM = ClaimProfileViewModel()

    var body: some View {
        AuthScreen(
            title: preview.familyName,
            subtitle: "\(preview.memberCount) member\(preview.memberCount == 1 ? "" : "s") already",
            systemImage: "house.fill",
            centered: true
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text("I am a...")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.dashNavy)

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

                NavigationLink(destination: RegisterView(
                    path: .joinFamily(inviteCode: preview.inviteCode, role: selectedRole)
                )) {
                    Text("Create my account →")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 6)

                if selectedRole == "child" && !preview.unclaimedChildren.isEmpty {
                    Button {
                        navigateToClaim = true
                    } label: {
                        Text("I already have a profile →")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .navigationDestination(isPresented: $navigateToClaim) {
            ClaimStep2View(vm: claimVM, familyPreview: preview)
        }
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
                Text(emoji).font(.system(size: 30))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .dashBlue : .dashSubtle)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .dashboardCard(radius: 16,
                           fill: isSelected ? .dashBlueTint : .white,
                           border: isSelected ? .dashBlue : .dashCardBorder)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.dashBlue, lineWidth: isSelected ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
    }
}
