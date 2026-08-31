import SwiftUI
import RevenueCat

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Your free trial has ended")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Subscribe to keep your family organised with Doto.")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                if let current = subscriptionManager.offerings?.current {
                    VStack(spacing: 12) {
                        ForEach(current.availablePackages, id: \.identifier) { package in
                            PackageButton(package: package) {
                                Task {
                                    let success = await subscriptionManager.purchase(package)
                                    if success { dismiss() }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                } else if subscriptionManager.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Text("Unable to load subscription options.")
                        .font(.system(size: 14))
                        .foregroundColor(.textMuted)
                        .padding()
                }

                Button {
                    Task { await subscriptionManager.restorePurchases() }
                } label: {
                    Text("Restore purchases")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.memberBlue)
                }

                Spacer()
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Subscribe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await subscriptionManager.loadOfferings()
            }
            .alert("Something went wrong",
                   isPresented: Binding(
                    get: { subscriptionManager.errorMessage != nil },
                    set: { if !$0 { subscriptionManager.errorMessage = nil } }
                   )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(subscriptionManager.errorMessage ?? "")
            }
        }
    }
}

private struct PackageButton: View {
    let package: Package
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.storeProduct.localizedTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    if package.storeProduct.introductoryDiscount != nil {
                        Text("Free trial available")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                Spacer()

                Text(package.localizedPriceString)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.memberBlue)
            .cornerRadius(12)
        }
    }
}
