import Foundation
import RevenueCat

@MainActor
final class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var offerings: Offerings?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let trialStartKey = "com.doto.subscription.trialStartDate"
    private let trialLength: TimeInterval = 30 * 24 * 60 * 60

    private override init() {
        super.init()
    }

    // MARK: - Trial

    var trialStartDate: Date? {
        get { UserDefaults.standard.object(forKey: trialStartKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: trialStartKey) }
    }

    func beginTrialIfNeeded() {
        guard trialStartDate == nil else { return }
        trialStartDate = Date()
    }

    var trialDaysRemaining: Int {
        guard let start = trialStartDate else { return 30 }
        let end = start.addingTimeInterval(trialLength)
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
        return max(0, remaining)
    }

    var isTrialActive: Bool {
        guard let start = trialStartDate else { return true }
        return Date().timeIntervalSince(start) < trialLength
    }

    // MARK: - RevenueCat

    var isSubscribed: Bool {
        guard let info = customerInfo else { return false }
        return info.entitlements.active.isEmpty == false
    }

    /// A parent needs to subscribe once the 30-day trial has ended.
    func shouldShowPaywall(for profile: Profile?) -> Bool {
        guard let profile, profile.isParent else { return false }
        return !isTrialActive && !isSubscribed
    }

    func setUserID(_ userID: String?) {
        guard let userID else { return }
        Purchases.shared.logIn(userID) { _, _, _ in }
    }

    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ package: Package) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            self.customerInfo = result.customerInfo
            return !result.userCancelled && result.customerInfo.entitlements.active.isEmpty == false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            self.customerInfo = info
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
        }
    }
}
