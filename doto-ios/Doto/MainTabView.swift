import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        if authVM.currentProfile?.isChild == true {
            TabView {
                DashboardView()
                    .tabItem { Label("Home",    systemImage: "house.fill") }
                TasksView()
                    .tabItem { Label("Tasks",   systemImage: "checkmark.circle.fill") }
                RewardsView()
                    .tabItem { Label("Rewards", systemImage: "star.fill") }
            }
            .accentColor(.memberBlue)
        } else {
            TabView {
                DashboardView()
                    .tabItem { Label("Home",     systemImage: "house.fill") }
                ScheduleView()
                    .tabItem { Label("Schedule", systemImage: "calendar") }
                TasksView()
                    .tabItem { Label("Tasks",    systemImage: "checkmark.circle.fill") }
                ShoppingView()
                    .tabItem { Label("Shop",     systemImage: "cart.fill") }
                RewardsView()
                    .tabItem { Label("Rewards",  systemImage: "star.fill") }
            }
            .accentColor(.memberBlue)
        }
    }
}
