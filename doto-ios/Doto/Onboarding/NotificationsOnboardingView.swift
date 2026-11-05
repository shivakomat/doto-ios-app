import SwiftUI
import UserNotifications

struct NotificationsOnboardingView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        AuthScreen(
            title: "Stay in the loop",
            subtitle: "Get notified when tasks are assigned, schedules conflict, or your weekly digest is ready.",
            systemImage: "bell.fill",
            iconColor: Color(hex: "#E8A317"),
            centered: true,
            showLandscape: true,
            footer: {
                AnyView(
                    VStack(spacing: 14) {
                        PrimaryButton(title: "Enable notifications") {
                            Task { await enableNotifications() }
                        }
                        Button {
                            markSeenAndProceed(enabled: false)
                        } label: {
                            Text("Not now — I'll enable later")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.dashSubtle)
                        }
                    }
                    .padding(.bottom, 4)
                )
            }
        ) {
            EmptyView()
        }
        .navigationBarHidden(true)
    }

    private func enableNotifications() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
        markSeenAndProceed(enabled: granted)
    }

    private func markSeenAndProceed(enabled: Bool) {
        UserDefaults.standard.set(true, forKey: "hasSeenNotificationsOnboarding")
        if !enabled {
            UserDefaults.standard.set(false, forKey: "notificationsEnabled")
        }
        Task { await authVM.refreshProfile() }
    }
}
