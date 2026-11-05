import SwiftUI

private struct AuthFieldChrome: ViewModifier {
    let focused: Bool
    var error: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(error ? Color.dashRed : (focused ? Color.dashBlue : Color.dashCardBorder),
                            lineWidth: focused || error ? 1.5 : 1)
            )
            .shadow(color: Color.dashNavy.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

struct AuthTextField: View {
    let label: String
    @Binding var text: String
    var autocapitalization: TextInputAutocapitalization = .sentences
    var keyboardType: UIKeyboardType = .default
    var placeholder: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.dashNavy)
            TextField(placeholder, text: $text)
                .focused($focused)
                .textInputAutocapitalization(autocapitalization)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .font(.system(size: 16))
                .foregroundColor(.dashNavy)
                .modifier(AuthFieldChrome(focused: focused))
        }
    }
}

struct AuthSecureField: View {
    let label: String
    @Binding var text: String
    @Binding var showPassword: Bool
    var error: String? = nil
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.dashNavy)
            HStack {
                Group {
                    if showPassword {
                        TextField("", text: $text)
                    } else {
                        SecureField("", text: $text)
                    }
                }
                .focused($focused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.system(size: 16))
                .foregroundColor(.dashNavy)

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.dashSubtle)
                        .font(.system(size: 16))
                }
            }
            .modifier(AuthFieldChrome(focused: focused, error: error != nil))

            if let err = error {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(.dashRedText)
            }
        }
    }
}

private struct AuthPrimaryLabel: View {
    let title: String
    var isLoading = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        HStack(spacing: 8) {
            if isLoading { ProgressView().tint(.white) }
            Text(title)
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(isEnabled ? Color.dashBlue : Color(hex: "#A9BCDD"))
        .clipShape(Capsule())
        .shadow(color: Color.dashBlue.opacity(isEnabled ? 0.3 : 0), radius: 8, x: 0, y: 4)
    }
}

/// Press feedback without SwiftUI's default disabled dimming (the label draws its own disabled state).
private struct AuthPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AuthPrimaryLabel(title: title, isLoading: isLoading)
        }
        .buttonStyle(AuthPressStyle())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.dashBlue.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(Capsule())
            .shadow(color: Color.dashBlue.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.dashBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.dashBlue, lineWidth: 1.5))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
