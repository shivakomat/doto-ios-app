import SwiftUI

struct ParentalConsentView: View {
    let onContinue: () -> Void
    let onCancel: () -> Void

    @State private var hasRead = false
    @State private var agrees = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Parental Consent")
                        .font(.system(size: 28, weight: .bold))
                    Text("Before adding a child to Doto, we need your consent to collect limited information from your child's profile.")
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    BulletLabel(text: "Child display name and role are stored to support family features.")
                    BulletLabel(text: "We do not collect email, photos, location, or advertising identifiers from children.")
                    BulletLabel(text: "Your child's data is not sold or used for advertising.")
                    BulletLabel(text: "You can review or remove your child from the family at any time.")
                }

                Spacer()

                VStack(spacing: 12) {
                    Toggle(isOn: $hasRead) {
                        Text("I have read and understand the Doto privacy practices for children.")
                            .font(.system(size: 14))
                    }
                    .toggleStyle(CheckboxToggleStyle())

                    Toggle(isOn: $agrees) {
                        Text("I am the child's parent or legal guardian and I consent to Doto collecting this information.")
                            .font(.system(size: 14))
                    }
                    .toggleStyle(CheckboxToggleStyle())

                    Button {
                        if hasRead && agrees {
                            onContinue()
                        }
                    } label: {
                        Text("I Consent")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background((hasRead && agrees) ? Color.memberBlue : Color.textMuted)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!hasRead || !agrees)
                    .padding(.top, 8)
                }
            }
            .padding(24)
            .navigationTitle("Consent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
    }
}

private struct BulletLabel: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.memberBlue)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 14))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(configuration.isOn ? .memberBlue : .textMuted)
                configuration.label
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
