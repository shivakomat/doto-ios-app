import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = DashboardViewModel()

    var body: some View {
        Group {
            if authVM.currentProfile?.isParent == true {
                ParentDashboardView(vm: vm)
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
