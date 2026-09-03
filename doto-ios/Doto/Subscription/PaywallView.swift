import SwiftUI
import RevenueCat

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var selectedPackage: Package?
    @State private var isAnnual: Bool = true
    @State private var showTerms = false

    private let benefits = [
        "Unlimited family schedules",
        "Rewards & goals for kids",
        "Shared shopping lists",
        "Full task management",
        "Sync across all family devices"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    heroSection
                    benefitsSection
                    offeringsSection
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Doto Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await subscriptionManager.loadOfferings()
                preselectPackage()
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
            .sheet(isPresented: $showTerms) {
                TermsOfServiceView()
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            VStack(spacing: 6) {
                Text("Unlock the full Doto experience")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Keep your family organised with premium features.")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What you get")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "#1D9E75"))
                            .font(.system(size: 18))

                        Text(benefit)
                            .font(.system(size: 15))
                            .foregroundColor(.textPrimary)

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Offerings

    @ViewBuilder
    private var offeringsSection: some View {
        if subscriptionManager.isLoading && subscriptionManager.offerings == nil {
            ProgressView()
                .padding(.vertical, 20)
        } else if let current = subscriptionManager.offerings?.current, !current.availablePackages.isEmpty {
            VStack(spacing: 16) {
                if hasBothMonthlyAndAnnual(current.availablePackages) {
                    billingToggle
                }

                VStack(spacing: 12) {
                    ForEach(filteredPackages(from: current.availablePackages), id: \.identifier) { package in
                        PackageCard(
                            package: package,
                            isSelected: selectedPackage?.identifier == package.identifier,
                            isPopular: isPopular(package)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPackage = package
                            }
                        }
                    }
                }

                subscribeButton
            }
        } else {
            VStack(spacing: 8) {
                Text("Unable to load subscription options.")
                    .font(.system(size: 15))
                    .foregroundColor(.textMuted)
                Button("Try again") {
                    Task { await subscriptionManager.loadOfferings() }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.memberBlue)
            }
            .padding(.vertical, 20)
        }
    }

    private var billingToggle: some View {
        HStack(spacing: 0) {
            billingToggleOption(title: "Monthly", isSelected: !isAnnual) {
                isAnnual = false
                selectPackage(for: false)
            }
            billingToggleOption(title: "Annual", isSelected: isAnnual) {
                isAnnual = true
                selectPackage(for: true)
            }
        }
        .background(Color(hex: "#F2F2F7"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 4)
    }

    private func billingToggleOption(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .textPrimary : .textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.white : Color.clear)
                .cornerRadius(8)
                .shadow(color: isSelected ? .black.opacity(0.06) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var subscribeButton: some View {
        Button {
            guard let package = selectedPackage else { return }
            Task {
                let success = await subscriptionManager.purchase(package)
                if success { dismiss() }
            }
        } label: {
            HStack {
                if subscriptionManager.isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding(.trailing, 6)
                }

                Text(selectedPackage == nil ? "Select a plan" : "Subscribe")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedPackage == nil ? Color.textMuted : Color.memberBlue)
            .cornerRadius(12)
        }
        .disabled(selectedPackage == nil || subscriptionManager.isLoading)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 16) {
            Button {
                Task { await subscriptionManager.restorePurchases() }
            } label: {
                Text("Restore purchases")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.memberBlue)
            }

            HStack(spacing: 4) {
                Text("By subscribing you agree to our")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)

                Button {
                    showTerms = true
                } label: {
                    Text("Terms")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.memberBlue)
                }

                Text("and")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)

                Button {
                    if let url = LegalURLs.privacyPolicy {
                        openURL(url)
                    }
                } label: {
                    Text("Privacy Policy")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.memberBlue)
                }
            }
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers

    private func preselectPackage() {
        guard let current = subscriptionManager.offerings?.current else { return }
        let packages = current.availablePackages
        if let annual = packages.first(where: { $0.packageType == .annual }) {
            selectedPackage = annual
            isAnnual = true
        } else if let monthly = packages.first(where: { $0.packageType == .monthly }) {
            selectedPackage = monthly
            isAnnual = false
        } else {
            selectedPackage = packages.first
            isAnnual = false
        }
    }

    private func hasBothMonthlyAndAnnual(_ packages: [Package]) -> Bool {
        packages.contains(where: { $0.packageType == .annual }) &&
        packages.contains(where: { $0.packageType == .monthly })
    }

    private func filteredPackages(from packages: [Package]) -> [Package] {
        let target: PackageType = isAnnual ? .annual : .monthly
        let matches = packages.filter { $0.packageType == target }
        return matches.isEmpty ? packages : matches
    }

    private func selectPackage(for annual: Bool) {
        guard let current = subscriptionManager.offerings?.current else { return }
        let packages = current.availablePackages
        let target: PackageType = annual ? .annual : .monthly
        selectedPackage = packages.first { $0.packageType == target }
            ?? packages.first
    }

    private func isPopular(_ package: Package) -> Bool {
        package.packageType == .annual
    }
}

// MARK: - Package Card

private struct PackageCard: View {
    let package: Package
    let isSelected: Bool
    let isPopular: Bool
    let action: () -> Void

    private var trialText: String? {
        guard package.storeProduct.introductoryDiscount != nil else { return nil }
        return "Free trial"
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(package.storeProduct.localizedTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(isSelected ? .textPrimary : .textSecondary)

                        if isPopular {
                            Text("Most Popular")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "#1D9E75"))
                                .clipShape(Capsule())
                        }
                    }

                    if let trial = trialText {
                        Text(trial)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#1D9E75"))
                    }

                    Text(package.localizedPriceString + subscriptionPeriodSuffix)
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.memberBlue : Color(hex: "#D1D1D6"), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.memberBlue)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.memberBlue.opacity(0.08) : Color(hex: "#F9F9FB"))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.memberBlue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var subscriptionPeriodSuffix: String {
        switch package.packageType {
        case .annual: return "/year"
        case .monthly: return "/month"
        case .weekly: return "/week"
        default: return ""
        }
    }
}
