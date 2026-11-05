import SwiftUI

/// Page container for sign-in, sign-up and onboarding screens: sky gradient
/// background, optional hero icon, large navy title and subtitle, scrollable
/// content and an optional pinned footer (primary action).
struct AuthScreen<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var iconColor: Color = .dashBlue
    var centered: Bool = false
    var showLandscape: Bool = false
    var footer: (() -> AnyView)? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            DashboardBackground(showLandscape: showLandscape)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: centered ? .center : .leading, spacing: 18) {
                    header
                    content()
                }
                .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let footer {
                footer()
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(
                        Color.white.opacity(0.95)
                            .overlay(alignment: .top) { Rectangle().fill(Color.dashCardBorder).frame(height: 1) }
                            .ignoresSafeArea(edges: .bottom)
                    )
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 68, height: 68)
                    .background(iconColor.opacity(0.14))
                    .clipShape(Circle())
                    .padding(.top, centered ? 16 : 0)
            }
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.dashNavy)
                .multilineTextAlignment(centered ? .center : .leading)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.dashSubtle)
                    .multilineTextAlignment(centered ? .center : .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .padding(.bottom, 4)
    }
}

/// Inline error / hint banner for auth forms.
struct AuthMessage: View {
    enum Kind { case error, warning, success }
    let text: String
    var kind: Kind = .error

    private var color: Color {
        switch kind {
        case .error:   return .dashRedText
        case .warning: return Color(hex: "#B7791F")
        case .success: return .dashGreen
        }
    }
    private var tint: Color {
        switch kind {
        case .error:   return .dashRedTint
        case .warning: return Color(hex: "#FEF6DC")
        case .success: return .dashGreenTint
        }
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Rounded white card for grouped content on auth screens.
struct AuthCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dashboardCard(radius: 16)
    }
}

/// Square check toggle used for consents.
struct DashboardCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(configuration.isOn ? .dashBlue : Color(hex: "#C5CCD9"))
                configuration.label
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.dashNavy)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Checkmark bullet used on privacy / consent screens.
struct DashboardBullet: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.dashGreen)
                .font(.system(size: 16))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.dashNavy)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

extension View {
    /// Restyles a `Form`/`List` screen to sit on the sky gradient with blue accents.
    func dashboardForm() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(DashboardBackground(showLandscape: false))
            .tint(.dashBlue)
    }
}
