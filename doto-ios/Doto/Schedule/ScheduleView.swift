import SwiftUI

struct ScheduleView: View {
    var isReadOnly: Bool = false
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm: ScheduleViewModel

    @State private var showAddEvent  = false
    @State private var showSearch    = false
    @State private var swipeOffset:  CGFloat = 0

    init(isReadOnly: Bool = false, vm: ScheduleViewModel = ScheduleViewModel()) {
        self.isReadOnly = isReadOnly
        _vm = StateObject(wrappedValue: vm)
    }

    private var currentProfileId: String? {
        isReadOnly ? authVM.currentProfile?.id : nil
    }

    /// The footer illustration only appears when the screen is tall enough and
    /// the mode has room for it (never in Month, which is already dense).
    private func showsFooter(height: CGFloat) -> Bool {
        height > 700 && vm.viewMode != .month
    }

    var body: some View {
        GeometryReader { geo in
            content(showFooter: showsFooter(height: geo.size.height))
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .navigationBarHidden(true)
        .simultaneousGesture(swipeGesture)
        .task { await vm.loadIfNeeded(for: vm.selectedDate) }
        .sheet(isPresented: $showAddEvent,
               onDismiss: { Task { await vm.load(monthStart: vm.selectedDate.monthStart) } }) {
            AddEditEventView(event: nil)
        }
        .sheet(isPresented: $showSearch) {
            ScheduleSearchSheet(vm: vm)
        }
        .alert("Something went wrong",
               isPresented: Binding(get: { vm.errorMessage != nil },
                                    set: { if !$0 { vm.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private func content(showFooter: Bool) -> some View {
        ZStack(alignment: .bottomTrailing) {
            DashboardBackground(showLandscape: showFooter)

            VStack(spacing: 0) {
                ScheduleHeader(
                    vm: vm,
                    isReadOnly: isReadOnly,
                    onAddTap: { showAddEvent = true },
                    onSearchTap: { showSearch = true }
                )
                ScheduleDateRow(vm: vm)

                if vm.isLoading && vm.events.isEmpty {
                    LoadingView()
                } else {
                    Group {
                        switch vm.viewMode {
                        case .week:
                            WeekView(vm: vm, isReadOnly: isReadOnly, currentProfileId: currentProfileId)
                                .transition(.asymmetric(
                                    insertion: .move(edge: swipeOffset < 0 ? .trailing : .leading),
                                    removal:   .move(edge: swipeOffset < 0 ? .leading  : .trailing)
                                ))
                        case .month:
                            MonthView(vm: vm, isReadOnly: isReadOnly)
                                .transition(.opacity)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.85), value: vm.selectedDate)
                    .animation(.easeInOut(duration: 0.2), value: vm.viewMode)
                                    }
            }

            // FAB for adding events (parent only)
            if !isReadOnly {
                Button {
                    showAddEvent = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.dashBlue)
                        .clipShape(Circle())
                        .shadow(color: Color.dashBlue.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in swipeOffset = value.translation.width }
            .onEnded { value in
                let velocity  = value.predictedEndTranslation.width - value.translation.width
                let threshold: CGFloat = 50
                if value.translation.width < -threshold || velocity < -200 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        vm.navigateForward()
                    }
                } else if value.translation.width > threshold || velocity > 200 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        vm.navigateBack()
                    }
                }
                swipeOffset = 0
            }
    }
}
