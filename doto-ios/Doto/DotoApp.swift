import SwiftUI
import RevenueCat

@main
struct DotoApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    init() {
        Purchases.configure(withAPIKey: "test_CLokzPfMsOmKGutpZlazMOrTEoj")
        Purchases.shared.delegate = SubscriptionManager.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(subscriptionManager)
                .preferredColorScheme(.light)
        }
    }
}
