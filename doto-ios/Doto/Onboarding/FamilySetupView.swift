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
        AuthScreen(
            title: "Set up your family",
            subtitle: "Step 2 of 3",
            systemImage: "house.fill",
            footer: {
                AnyView(
                    Group {
                        if createdFamily == nil {
                            PrimaryButton(
                                title: isLoading ? "Creating..." : "Create family →",
                                isLoading: isLoading
                            ) {
                                Task { await submit() }
                            }
                            .disabled(isLoading || familyName.trimmingCharacters(in: .whitespaces).isEmpty)
                        } else {
                            PrimaryButton(title: "Continue →") {
                                showNotificationsOnboarding = true
                            }
                        }
                    }
                )
            }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                AuthTextField(label: "Family name", text: $familyName)
                    .focused($focusFamilyName)
                    .onAppear { focusFamilyName = true }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your profile")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.dashNavy)

                    HStack(spacing: 12) {
                        AvatarView(
                            name: authVM.currentProfile?.displayName ?? "?",
                            color: authVM.currentProfile?.color ?? "#185FA5",
                            size: 40,
                            isActive: true
                        )
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(authVM.currentProfile?.displayName ?? "")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.dashNavy)
                                Text("(you)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.dashSubtle)
                            }
                            DashboardBadge(text: "Parent", foreground: .dashBlue, background: .dashBlueTint)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .dashboardCard(radius: 14, fill: .dashBlueTint.opacity(0.6), border: .dashBlueBorder)
                }

                if let family = createdFamily {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Invite your family")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.dashNavy)
                        Text("Share this code with your partner and children so they can join.")
                            .font(.system(size: 13))
                            .foregroundColor(.dashSubtle)
                    }
                    .padding(.top, 4)

                    InviteCodeView(code: family.inviteCode, familyName: family.name)
                }

                if let err = errorMessage {
                    AuthMessage(text: err)
                }
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
            let res: FamilyTokenResponse = try await APIClient.shared.post(
                "/families",
                body: FamilyCreateRequest(name: familyName.trimmingCharacters(in: .whitespaces))
            )
            KeychainHelper.saveToken(res.token)
            createdFamily = res.family
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
