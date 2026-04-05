import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var selectedColor = "#6C63FF"
    @State private var familyName = ""
    @State private var showFamilyManage = false
    @State private var showRewardCatalog = false
    @State private var showChangePassword = false
    @State private var isSavingProfile = false
    @State private var isSavingFamily = false

    private let colorPalette = Color.settingsColorPalette

    var body: some View {
        NavigationView {
            Form {
                profileSection
                familySection
                notificationsSection
                dangerSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Something went wrong",
                   isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .alert("Success",
                   isPresented: Binding(get: { vm.successMessage != nil }, set: { if !$0 { vm.successMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.successMessage ?? "")
            }
        }
        .onAppear {
            displayName = authVM.currentProfile?.displayName ?? ""
            selectedColor = authVM.currentProfile?.color ?? "#6C63FF"
            familyName = vm.family?.name ?? ""
            Task { 
                await vm.loadFamily()
                await vm.loadNotifications()
            }
        }
        .onChange(of: vm.family?.id) { _ in
            familyName = vm.family?.name ?? ""
        }
        .sheet(isPresented: $showFamilyManage) {
            FamilyManageView()
        }
        .sheet(isPresented: $showRewardCatalog) {
            RewardCatalogView()
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView(vm: vm)
        }
        .confirmationDialog(
            "Leave family?",
            isPresented: $vm.showLeaveConfirm,
            titleVisibility: .visible
        ) {
            Button("Leave family", role: .destructive) {
                Task { await vm.leaveFamily(authVM: authVM) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will lose access to all family data. This cannot be undone.")
        }
        .confirmationDialog(
            "Delete account?",
            isPresented: $vm.showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete my account", role: .destructive) {
                Task { await vm.deleteAccount(authVM: authVM) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your account and all your data will be permanently deleted. This cannot be undone.")
        }
    }

    private var profileSection: some View {
        Section(header: Text("Profile")) {
            HStack {
                Text("Name")
                Spacer()
                TextField("Display name", text: $displayName)
                    .multilineTextAlignment(.trailing)
            }

            HStack {
                Text("Colour")
                Spacer()
                HStack(spacing: 6) {
                    ForEach(colorPalette, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedColor == hex ? 2 : 0)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: hex), lineWidth: selectedColor == hex ? 3 : 0)
                            )
                            .onTapGesture { selectedColor = hex }
                    }
                }
            }

            Button {
                Task {
                    isSavingProfile = true
                    await vm.updateProfile(displayName: displayName, color: selectedColor)
                    await authVM.refreshCurrentProfileOnly()
                    isSavingProfile = false
                }
            } label: {
                HStack {
                    Text("Save Profile")
                        .foregroundColor(.memberBlue)
                    if isSavingProfile { Spacer(); ProgressView() }
                }
            }
            .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty || isSavingProfile)

            Button("Change password") { showChangePassword = true }
        }
    }

    private var familySection: some View {
        Section(header: Text("Family")) {
            HStack {
                Text("Family name")
                Spacer()
                TextField("Family name", text: $familyName)
                    .multilineTextAlignment(.trailing)
            }

            Button {
                Task {
                    isSavingFamily = true
                    await vm.updateFamilyName(familyName)
                    isSavingFamily = false
                }
            } label: {
                HStack {
                    Text("Save Family Name")
                        .foregroundColor(.memberBlue)
                    if isSavingFamily { Spacer(); ProgressView() }
                }
            }
            .disabled(familyName.trimmingCharacters(in: .whitespaces).isEmpty || isSavingFamily)

            if let code = vm.family?.inviteCode {
                HStack {
                    Text("Invite code")
                    Spacer()
                    Text(code)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.textSecondary)
                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.memberBlue)
                    }
                }
            }

            Button("Manage members") { showFamilyManage = true }
            Button("Reward catalog") { showRewardCatalog = true }
        }
    }

    private var notificationsSection: some View {
        Section(header: Text("Notifications")) {
            Toggle("Task assigned", isOn: $vm.notifications.taskAssigned)
                .onChange(of: vm.notifications.taskAssigned) { _ in
                    Task { await vm.saveNotifications() }
                }
            Toggle("Task overdue", isOn: $vm.notifications.taskOverdue)
                .onChange(of: vm.notifications.taskOverdue) { _ in
                    Task { await vm.saveNotifications() }
                }
            Toggle("Task completed", isOn: $vm.notifications.taskCompleted)
                .onChange(of: vm.notifications.taskCompleted) { _ in
                    Task { await vm.saveNotifications() }
                }
            Toggle("Schedule conflict", isOn: $vm.notifications.scheduleConflict)
                .onChange(of: vm.notifications.scheduleConflict) { _ in
                    Task { await vm.saveNotifications() }
                }
            Toggle("Reward pending", isOn: $vm.notifications.rewardPending)
                .onChange(of: vm.notifications.rewardPending) { _ in
                    Task { await vm.saveNotifications() }
                }
            Toggle("Reward approved", isOn: $vm.notifications.rewardApproved)
                .onChange(of: vm.notifications.rewardApproved) { _ in
                    Task { await vm.saveNotifications() }
                }
            Toggle("Streak at risk", isOn: $vm.notifications.streakAtRisk)
                .onChange(of: vm.notifications.streakAtRisk) { _ in
                    Task { await vm.saveNotifications() }
                }
            Toggle("Bonus points", isOn: $vm.notifications.bonusPoints)
                .onChange(of: vm.notifications.bonusPoints) { _ in
                    Task { await vm.saveNotifications() }
                }
            Toggle("Weekly digest", isOn: $vm.notifications.weeklyDigest)
                .onChange(of: vm.notifications.weeklyDigest) { _ in
                    Task { await vm.saveNotifications() }
                }
        }
    }

    private var dangerSection: some View {
        Section(header: Text("Account")) {
            Button(role: .destructive) {
                authVM.logout()
                dismiss()
            } label: {
                Text("Log out")
            }

            Button(role: .destructive) {
                vm.showLeaveConfirm = true
            } label: {
                Text("Leave family")
                    .foregroundColor(.orange)
            }

            Button(role: .destructive) {
                vm.showDeleteConfirm = true
            } label: {
                Text("Delete account")
                    .foregroundColor(.red)
            }
            .disabled(true)
        }
    }
}

struct ChangePasswordView: View {
    @ObservedObject var vm: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var newPw = ""
    @State private var confirm = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Current password", text: $current)
                    SecureField("New password", text: $newPw)
                    SecureField("Confirm new password", text: $confirm)
                }
                if let err = error {
                    Section { Text(err).foregroundColor(.red).font(.caption) }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading { ProgressView() }
                    else {
                        Button("Save") {
                            guard newPw == confirm else { error = "Passwords don't match"; return }
                            guard newPw.count >= 8 else { error = "Password must be at least 8 characters"; return }
                            Task {
                                isLoading = true
                                await vm.changePassword(current: current, new: newPw)
                                isLoading = false
                                if vm.errorMessage == nil { dismiss() }
                            }
                        }
                        .disabled(current.isEmpty || newPw.isEmpty || confirm.isEmpty)
                    }
                }
            }
        }
    }
}
