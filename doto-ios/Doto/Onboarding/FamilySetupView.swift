import SwiftUI

struct FamilyCreateRequest: Encodable { let name: String }

struct FamilySetupView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var familyName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var createdFamily: Family?
    @State private var showNotificationsOnboarding = false
    @FocusState private var focusFamilyName: Bool

    var body: some View {
        VStack(spacing: 0) {
            DotoNavHeader(title: "Set up your family", trailing: {
                AnyView(
                    Text("Step 2 of 3")
                        .font(.system(size: 12))
                        .foregroundColor(.appNavySub)
                )
            })

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    AuthTextField(label: "Family name", text: $familyName)
                        .focused($focusFamilyName)
                        .onAppear { focusFamilyName = true }

                    Divider()

                    Text("Your profile")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSecondary)

                    HStack(spacing: 12) {
                        AvatarView(
                            name: authVM.currentProfile?.displayName ?? "?",
                            color: authVM.currentProfile?.color ?? "#185FA5",
                            size: 36,
                            isActive: true
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(authVM.currentProfile?.displayName ?? "")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("(you)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textMuted)
                            }
                            Text("Parent")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.memberBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#EFF6FF"))
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(hex: "#EFF6FF"))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.memberBlue.opacity(0.3), lineWidth: 1))
                    .cornerRadius(8)

                    if let family = createdFamily {
                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Invite your family")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textSecondary)
                            Text("Share this code with your partner and children so they can join.")
                                .font(.system(size: 12))
                                .foregroundColor(.textMuted)
                        }

                        InviteCodeView(code: family.inviteCode, familyName: family.name)
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }

                    PrimaryButton(
                        title: isLoading ? "Creating..." : "Continue →",
                        isLoading: isLoading
                    ) {
                        Task { await submit() }
                    }
                    .disabled(isLoading || familyName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showNotificationsOnboarding) {
            NotificationsOnboardingView()
        }
    }

    private func submit() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let family: Family = try await APIClient.shared.post(
                "/families",
                body: FamilyCreateRequest(name: familyName.trimmingCharacters(in: .whitespaces))
            )
            createdFamily = family
            await authVM.refreshCurrentProfileOnly()
            showNotificationsOnboarding = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
