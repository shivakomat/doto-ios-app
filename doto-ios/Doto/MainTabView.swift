import SwiftUI

enum DotoTab: Int {
    case home = 0, schedule, tasks, shopping, rewards
}

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab: DotoTab = .home

    var body: some View {
        if authVM.currentProfile?.isChild == true {
            TabView(selection: $selectedTab) {
                DashboardView(selectedTab: $selectedTab)
                    .tag(DotoTab.home)
                    .tabItem { Label("Home",    systemImage: "house.fill") }
                ScheduleView(isReadOnly: true)
                    .tag(DotoTab.schedule)
                    .tabItem { Label("Schedule", systemImage: "calendar") }
                TasksView()
                    .tag(DotoTab.tasks)
                    .tabItem { Label("Tasks",   systemImage: "checkmark.circle.fill") }
                ShoppingView(canManageLists: false)
                    .tag(DotoTab.shopping)
                    .tabItem { Label("Shopping", systemImage: "cart.fill") }
                RewardsView()
                    .tag(DotoTab.rewards)
                    .tabItem { Label("Rewards", systemImage: "star.fill") }
            }
            .accentColor(.memberBlue)
            .privacyScreen()
        } else {
            TabView(selection: $selectedTab) {
                DashboardView(selectedTab: $selectedTab)
                    .tag(DotoTab.home)
                    .tabItem { Label("Home",     systemImage: "house.fill") }
                ScheduleView()
                    .tag(DotoTab.schedule)
                    .tabItem { Label("Schedule", systemImage: "calendar") }
                TasksView()
                    .tag(DotoTab.tasks)
                    .tabItem { Label("Tasks",    systemImage: "checkmark.circle.fill") }
                ShoppingView()
                    .tag(DotoTab.shopping)
                    .tabItem { Label("Shopping Lists", systemImage: "cart.fill") }
                RewardsView()
                    .tag(DotoTab.rewards)
                    .tabItem { Label("Rewards",  systemImage: "star.fill") }
            }
            .accentColor(.memberBlue)
            .privacyScreen()
        }
    }
}
