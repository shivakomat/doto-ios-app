import SwiftUI

struct ClaimStep2View: View {
    @ObservedObject var vm: ClaimProfileViewModel
    let familyPreview: FamilyPreview
    @EnvironmentObject var authVM: AuthViewModel

    @State private var selectedProfileId: String = ""
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false

    private static let usernameRegex = /^[a-z0-9_]+$/
    private var usernameValid: Bool {
        let len = username.count
        return len >= 3 && len <= 50
            && ((try? Self.usernameRegex.wholeMatch(in: username)) != nil)
    }

    private var canSubmit: Bool {
        !selectedProfileId.isEmpty && usernameValid && password.count >= 8 && !vm.isLoading
    }

    var body: some View {
        Group {
            if let profile = vm.claimedProfile {
                successView(profile: profile)
            } else {
                claimForm
            }
        }
        .navigationTitle("Claim My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(vm.claimedProfile != nil)
        .toolbar {
            if vm.claimedProfile == nil {
                ToolbarItem(placement: .confirmationAction) {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Button("Claim") {
                            Task {
                                await vm.claimProfile(
                                    profileId: selectedProfileId,
                                    inviteCode: familyPreview.inviteCode,
                                    username: username,
                                    password: password,
                                    authVM: authVM
                                )
                            }
                        }
                        .disabled(!canSubmit)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            if selectedProfileId.isEmpty, let first = familyPreview.unclaimedChildren.first {
                selectedProfileId = first.id
            }
        }
    }

    private var claimForm: some View {
        Form {
            Section(header: Text("Choose your profile")) {
                ForEach(familyPreview.unclaimedChildren) { child in
                    Button {
                        selectedProfileId = child.id
                        vm.errorMessage = nil
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(
                                name: child.displayName,
                                color: child.color,
                                size: 32,
                                isActive: selectedProfileId == child.id
                            )
                            Text(child.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            Spacer()
                            if selectedProfileId == child.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.memberBlue)
                            }
                        }
                    }
                }
            }

            Section(header: Text("Create your login")) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: username) { _ in vm.errorMessage = nil }
                    if !username.isEmpty && !usernameValid {
                        Text("3–50 characters, lowercase letters, numbers and _ only")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                HStack {
                    Group {
                        if showPassword {
                            TextField("Minimum 8 characters", text: $password)
                        } else {
                            SecureField("Minimum 8 characters", text: $password)
                        }
                    }
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: password) { _ in vm.errorMessage = nil }

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.textMuted)
                    }
                }
            }

            if let err = vm.errorMessage {
                Section {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(.dashRedText)
                }
            }
        }
        .dashboardForm()
    }

    private func successView(profile: Profile) -> some View {
        AuthScreen(
            title: "Welcome, \(profile.displayName)! 🎉",
            subtitle: "Your profile is all set.",
            centered: true,
            showLandscape: true,
            footer: {
                AnyView(
                    PrimaryButton(title: "Let's go! →") {
                        vm.completeTransition(authVM: authVM)
                    }
                    .padding(.bottom, 4)
                )
            }
        ) {
            VStack(spacing: 20) {
                AvatarView(name: profile.displayName, color: profile.color, size: 80, isActive: true)

                HStack(spacing: 12) {
                    statPill(value: "\(profile.pointsTotal)", label: "Points", color: .dashBlue)
                    if let streak = profile.streak, streak > 0 {
                        statPill(value: "\(streak)", label: "Day streak 🔥", color: Color(hex: "#F2711C"))
                    }
                }
            }
        }
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.dashSubtle)
        }
        .frame(minWidth: 100)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .dashboardCard(radius: 16)
    }
}
