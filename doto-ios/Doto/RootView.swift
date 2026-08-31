import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    var body: some View {
        Group {
            switch authVM.state {
            case .unauthenticated:
                LandingView()
            case .noFamily:
                FamilySetupView()
            case .ready:
                if subscriptionManager.shouldShowPaywall(for: authVM.currentProfile) {
                    PaywallView()
                        .interactiveDismissDisabled()
                } else {
                    MainTabView()
                }
            }
        }
        .task { await authVM.restoreSession() }
    }
}
