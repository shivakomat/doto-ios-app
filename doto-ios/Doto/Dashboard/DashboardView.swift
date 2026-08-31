import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = DashboardViewModel()
    @Binding var selectedTab: DotoTab

    var body: some View {
        Group {
            if authVM.currentProfile?.isParent == true {
                ParentDashboardView(vm: vm, selectedTab: $selectedTab)
            } else {
                ChildDashboardView(vm: vm)
            }
        }
        .task {
            let role = authVM.currentProfile?.role ?? "parent"
            await vm.load(role: role)
        }
    }
}
