import SwiftUI
import RevenueCat

@main
struct DotoApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    init() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String, !apiKey.isEmpty else {
            fatalError("REVENUECAT_API_KEY missing from Info.plist. Ensure Secrets.xcconfig is included in the build.")
        }
        Purchases.configure(withAPIKey: apiKey)
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
