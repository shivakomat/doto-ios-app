import SwiftUI

struct ParentalConsentView: View {
    let onContinue: () -> Void
    let onCancel: () -> Void

    @State private var hasRead = false
    @State private var agrees = false

    var body: some View {
        NavigationView {
            AuthScreen(
                title: "Parental Consent",
                subtitle: "Before adding a child to Doto, we need your consent to collect limited information from your child's profile.",
                systemImage: "hand.raised.fill",
                footer: {
                    AnyView(
                        PrimaryButton(title: "I Consent") {
                            if hasRead && agrees {
                                onContinue()
                            }
                        }
                        .disabled(!hasRead || !agrees)
                    )
                }
            ) {
                VStack(spacing: 16) {
                    AuthCard {
                        VStack(alignment: .leading, spacing: 14) {
                            DashboardBullet(text: "Child display name and role are stored to support family features.")
                            DashboardBullet(text: "We do not collect email, photos, location, or advertising identifiers from children.")
                            DashboardBullet(text: "Your child's data is not sold or used for advertising.")
                            DashboardBullet(text: "You can review or remove your child from the family at any time.")
                        }
                    }

                    AuthCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle(isOn: $hasRead) {
                                Text("I have read and understand the Doto privacy practices for children.")
                                    .font(.system(size: 14))
                            }
                            .toggleStyle(DashboardCheckboxToggleStyle())

                            Toggle(isOn: $agrees) {
                                Text("I am the child's parent or legal guardian and I consent to Doto collecting this information.")
                                    .font(.system(size: 14))
                            }
                            .toggleStyle(DashboardCheckboxToggleStyle())
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
        .tint(.dashBlue)
    }
}
