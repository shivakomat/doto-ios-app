import SwiftUI

struct FamilyManageView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = FamilyViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showAddChild = false
    @State private var childName = ""
    @State private var memberToDelete: Profile?
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            List {
                if let family = vm.family {
                    Section(header: Text("Family")) {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(family.name)
                                .foregroundColor(.textSecondary)
                        }
                        HStack {
                            Text("Invite code")
                            Spacer()
                            Text(family.inviteCode)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.textSecondary)
                            Button {
                                UIPasteboard.general.string = family.inviteCode
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.memberBlue)
                            }
                        }
                    }

                    Section(header: Text("Members")) {
                        ForEach(family.members) { member in
                            HStack(spacing: 12) {
                                AvatarView(name: member.displayName, color: member.color, size: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.displayName)
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(member.role.capitalized)
                                        .font(.system(size: 11))
                                        .foregroundColor(.textMuted)
                                }
                                Spacer()
                                Text("\(member.points) pts")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if member.isChild {
                                    Button(role: .destructive) {
                                        memberToDelete = member
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }

                        Button {
                            showAddChild = true
                        } label: {
                            Label("Add child", systemImage: "person.badge.plus")
                                .foregroundColor(.memberBlue)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authVM.logout()
                        dismiss()
                    } label: {
                        Text("Log Out")
                    }
                }
            }
            .navigationTitle("Manage Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Remove member?", isPresented: $showDeleteAlert, presenting: memberToDelete) { member in
                Button("Remove", role: .destructive) {
                    Task { await vm.deleteMember(member) }
                }
                Button("Cancel", role: .cancel) {}
            } message: { member in
                Text("Remove \(member.displayName) from the family?")
            }
        }
        .task { await vm.load() }
        .alert("Something went wrong",
               isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .sheet(isPresented: $showAddChild) {
            NavigationView {
                Form {
                    Section(header: Text("Child's name")) {
                        TextField("Name", text: $childName)
                    }
                }
                .navigationTitle("Add Child")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddChild = false
                            childName = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let name = childName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            Task {
                                await vm.addChild(displayName: name)
                                childName = ""
                                showAddChild = false
                            }
                        }
                        .disabled(childName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }
}
