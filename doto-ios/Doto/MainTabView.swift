import SwiftUI

enum DotoTab: Int {
    case home = 0, schedule, tasks, shopping, rewards
}

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab: DotoTab = .home

    private var isChild: Bool { authVM.currentProfile?.isChild == true }

    private var items: [FloatingTabItem] {
        [
            FloatingTabItem(tab: .home,     title: "Home",     icon: "house.fill"),
            FloatingTabItem(tab: .schedule, title: "Schedule", icon: "calendar"),
            FloatingTabItem(tab: .tasks,    title: "Tasks",    icon: "checkmark.circle"),
            FloatingTabItem(tab: .shopping, title: isChild ? "Shopping" : "Shopping Lists", icon: "cart"),
            FloatingTabItem(tab: .rewards,  title: "Rewards",  icon: "star.fill")
        ]
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .floatingTabBarInset()
                .tag(DotoTab.home)
                .toolbar(.hidden, for: .tabBar)
            ScheduleView(isReadOnly: isChild)
                .floatingTabBarInset()
                .tag(DotoTab.schedule)
                .toolbar(.hidden, for: .tabBar)
            TasksView()
                .floatingTabBarInset()
                .tag(DotoTab.tasks)
                .toolbar(.hidden, for: .tabBar)
            ShoppingView(canManageLists: !isChild)
                .floatingTabBarInset()
                .tag(DotoTab.shopping)
                .toolbar(.hidden, for: .tabBar)
            RewardsView()
                .floatingTabBarInset()
                .tag(DotoTab.rewards)
                .toolbar(.hidden, for: .tabBar)
        }
        .accentColor(.dashBlue)
        .overlay(alignment: .bottom) {
            FloatingTabBar(items: items, selection: $selectedTab)
        }
        .privacyScreen()
    }
}
