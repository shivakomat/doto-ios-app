import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    var body: some View {
        Group {
            switch authVM.state {
            case .unauthenticated: AuthView()
            case .noFamily:        FamilySetupView()
            case .ready:           MainTabView()
            }
        }
        .task { await authVM.restoreSession() }
    }
}
