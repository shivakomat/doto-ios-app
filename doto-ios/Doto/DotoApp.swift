import SwiftUI

@main
struct DotoApp: App {
    @StateObject private var authVM = AuthViewModel()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(authVM)
        }
    }
}
