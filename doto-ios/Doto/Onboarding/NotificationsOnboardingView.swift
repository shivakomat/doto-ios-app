import SwiftUI
import UserNotifications

struct NotificationsOnboardingView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🔔")
                .font(.system(size: 44))

            Text("Stay in the loop")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.textPrimary)

            Text("Get notified when tasks are assigned, schedules conflict, or your weekly digest is ready.")
                .font(.system(size: 10))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Button {
                Task { await enableNotifications() }
            } label: {
                Text("Enable notifications")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.memberBlue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Button {
                markSeenAndProceed(enabled: false)
            } label: {
                Text("Not now — I'll enable later")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
            }

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
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
