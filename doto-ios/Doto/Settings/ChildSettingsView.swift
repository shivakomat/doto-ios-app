import SwiftUI

struct ChildSettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SettingsViewModel()

    @State private var displayName = ""
    @State private var selectedColor = "#6C63FF"
    @State private var showLogoutConfirm = false

    private let colorPalette = Color.settingsColorPalette

    var body: some View {
        NavigationView {
            Form {
                profileSection
                notificationsSection
                dangerSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Error",
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
            Task {
                await vm.loadNotifications()
            }
        }
        .confirmationDialog(
            "Log out?",
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Log out", role: .destructive) {
                authVM.logout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will be logged out of your account.")
        }
    }

    private var profileSection: some View {
        Section(header: Text("Profile")) {
            HStack {
                Text("Display name")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
                Spacer()
                TextField("Name", text: $displayName)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 14))
                    .onSubmit {
                        Task {
                            await vm.updateProfile(displayName: displayName, color: selectedColor)
                            await authVM.refreshCurrentProfileOnly()
                        }
                    }
            }

            // Simple color picker using palette
            HStack {
                Text("Color")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
                Spacer()
                HStack(spacing: 8) {
                    ForEach(colorPalette, id: \.self) { hex in
                        ZStack {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 24, height: 24)
                            if selectedColor == hex {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .onTapGesture {
                            selectedColor = hex
                            Task {
                                await vm.updateProfile(displayName: displayName, color: selectedColor)
                                await authVM.refreshCurrentProfileOnly()
                            }
                        }
                    }
                }
            }
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
        }
    }

    private var dangerSection: some View {
        Section(header: Text("Account")) {
            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                Text("Log out")
            }
        }
    }
}
