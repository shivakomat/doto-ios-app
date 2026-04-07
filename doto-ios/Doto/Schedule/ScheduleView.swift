import SwiftUI

struct ScheduleView: View {
    var isReadOnly: Bool = false
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ScheduleViewModel()

    @State private var showAddEvent  = false
    @State private var swipeOffset:  CGFloat = 0

    private var currentProfileId: String? {
        isReadOnly ? authVM.currentProfile?.id : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            ScheduleHeader(vm: vm, isReadOnly: isReadOnly, onAddTap: { showAddEvent = true })

            if vm.isLoading && vm.events.isEmpty {
                LoadingView()
            } else {
                Group {
                    switch vm.viewMode {
                    case .day:
                        DayView(vm: vm, isReadOnly: isReadOnly, currentProfileId: currentProfileId)
                            .transition(.asymmetric(
                                insertion: .move(edge: swipeOffset < 0 ? .trailing : .leading),
                                removal:   .move(edge: swipeOffset < 0 ? .leading  : .trailing)
                            ))
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
        .background(Color.screenBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .simultaneousGesture(
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
        )
        .task { await vm.loadIfNeeded(for: vm.selectedDate) }
        .sheet(isPresented: $showAddEvent,
               onDismiss: { Task { await vm.load(monthStart: vm.selectedDate.monthStart) } }) {
            AddEditEventView(event: nil)
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
}
