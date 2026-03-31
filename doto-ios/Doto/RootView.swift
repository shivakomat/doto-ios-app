import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    var body: some View {
        Group {
            switch authVM.state {
            case .unauthenticated: LandingView()
            case .noFamily:        FamilySetupView()
            case .ready:           MainTabView()
            }
        }
        .task { await authVM.restoreSession() }
    }
}
