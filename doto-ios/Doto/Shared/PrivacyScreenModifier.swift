import SwiftUI

struct PrivacyScreenModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if scenePhase == .background {
                        ZStack {
                            Color.black
                                .ignoresSafeArea()

                            VStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.textMuted)
                                Text("Doto")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .transition(.opacity)
                    }
                }
            )
    }
}

extension View {
    func privacyScreen() -> some View {
        modifier(PrivacyScreenModifier())
    }
}
