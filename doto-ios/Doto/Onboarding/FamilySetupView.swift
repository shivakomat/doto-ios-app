import SwiftUI

struct FamilyCreateRequest: Encodable { let name: String }
struct MemberCreateRequest: Encodable { let displayName: String; let color: String }

struct FamilySetupView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var familyName = ""
    @State private var partnerEmail = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddChildSheet = false
    @State private var childName = ""
    @State private var copiedToast = false
    @State private var createdInviteCode = ""
    @State private var createdFamilyId = ""
    @State private var pendingChildName: String? = nil
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
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Family name (e.g. The Smiths)", text: $familyName)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusFamilyName)
                        .padding(.horizontal)
                        .onAppear { focusFamilyName = true }

                    Divider().padding(.horizontal)

                    Text("Your profile")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal)

                    HStack(spacing: 12) {
                        AvatarView(name: authVM.currentProfile?.displayName ?? "?",
                                   color: authVM.currentProfile?.color ?? "#185FA5",
                                   size: 36,
                                   isActive: true)
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
                    .padding()
                    .background(Color(hex: "#EFF6FF"))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.memberBlue.opacity(0.4), lineWidth: 1))
                    .cornerRadius(8)
                    .padding(.horizontal)

                    Text("Invite family members")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal)

                    TextField("Partner's email address...", text: $partnerEmail)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding(.horizontal)

                    HStack(spacing: 12) {
                        Button {
                            showAddChildSheet = true
                        } label: {
                            Label("Add child", systemImage: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#F1F5F9"))
                                .cornerRadius(8)
                                .foregroundColor(.textPrimary)
                        }

                        Button {
                            let inviteURL = "https://app.getdoto.com/join/\(createdInviteCode.isEmpty ? "..." : createdInviteCode)"
                            UIPasteboard.general.string = inviteURL
                            withAnimation { copiedToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { copiedToast = false }
                            }
                        } label: {
                            Label("Copy link", systemImage: "doc.on.doc")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#F1F5F9"))
                                .cornerRadius(8)
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .padding(.horizontal)

                    if copiedToast {
                        Text("Copied!")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.doneText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.doneBg)
                            .cornerRadius(6)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    if let child = pendingChildName {
                        HStack(spacing: 8) {
                            AvatarView(name: child, color: Color.memberHexPalette[1], size: 24)
                            Text(child)
                                .font(.system(size: 13))
                            Spacer()
                            Text("Child")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.memberAmber)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#FEF3C7"))
                                .cornerRadius(4)
                        }
                        .padding()
                        .background(Color(hex: "#FFFBEB"))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    Text("You can add more people later in Settings")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)

                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.memberBlue)
                                .frame(height: 48)
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Continue →")
                                    .foregroundColor(.white)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .disabled(isLoading || familyName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showNotificationsOnboarding) {
            NotificationsOnboardingView()
        }
        .sheet(isPresented: $showAddChildSheet) {
            AddChildSheet(onAdd: { name in
                pendingChildName = name
            })
        }
    }

    private func submit() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let family: Family = try await APIClient.shared.post(
                "/families",
                body: FamilyCreateRequest(name: familyName.trimmingCharacters(in: .whitespaces))
            )
            createdInviteCode = family.inviteCode
            createdFamilyId   = family.id

            if let childName = pendingChildName, !childName.isEmpty {
                let nextColor = Color.memberHexPalette[min(1, Color.memberHexPalette.count - 1)]
                let _: Profile = try await APIClient.shared.post(
                    "/members",
                    body: MemberCreateRequest(displayName: childName, color: nextColor)
                )
            }

            await authVM.refreshCurrentProfileOnly()
            showNotificationsOnboarding = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AddChildSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (String) -> Void
    @State private var name = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Child's name")) {
                    TextField("Name", text: $name)
                }
            }
            .navigationTitle("Add child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                            onAdd(name.trimmingCharacters(in: .whitespaces))
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
