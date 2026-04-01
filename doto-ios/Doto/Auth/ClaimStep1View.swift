import SwiftUI

struct ClaimStep1View: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ClaimProfileViewModel()

    @State private var inviteCode = ""
    @State private var navigateToStep2 = false
    @State private var noProfilesMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter your family's invite code")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textSecondary)
                        TextField("XXXXXX", text: $inviteCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(size: 26, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .onChange(of: inviteCode) { newValue in
                                let filtered = newValue
                                    .uppercased()
                                    .filter { $0.isLetter || $0.isNumber }
                                inviteCode = String(filtered.prefix(6))
                                noProfilesMessage = nil
                                vm.errorMessage = nil
                            }
                    }
                    .padding(.vertical, 4)
                } footer: {
                    Text("Ask a parent in your family for the 6-character code.")
                        .font(.system(size: 12))
                }

                if let msg = noProfilesMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.memberAmber)
                            Text(msg)
                                .font(.system(size: 13))
                                .foregroundColor(.textPrimary)
                        }
                    }
                }

                if let err = vm.errorMessage {
                    Section {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Join Your Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Button("Continue") {
                            Task { await tryLoadPreview() }
                        }
                        .disabled(inviteCode.count != 6)
                        .fontWeight(.semibold)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToStep2) {
                if let preview = vm.familyPreview {
                    ClaimStep2View(vm: vm, familyPreview: preview)
                }
            }
        }
    }

    private func tryLoadPreview() async {
        await vm.loadPreview(code: inviteCode)
        guard let preview = vm.familyPreview, vm.errorMessage == nil else { return }
        if preview.unclaimedChildren.isEmpty {
            noProfilesMessage = "No unclaimed profiles in this family."
        } else {
            navigateToStep2 = true
        }
    }
}
