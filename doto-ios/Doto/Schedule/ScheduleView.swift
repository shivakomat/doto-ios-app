import SwiftUI

enum ScheduleViewMode: String, CaseIterable {
    case daily  = "Daily"
    case weekly = "Weekly"
}

struct ScheduleView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ScheduleViewModel()

    @State private var viewMode: ScheduleViewMode = .daily
    @State private var showAddEvent = false
    @State private var selectedEvent: DotoEvent?

    var body: some View {
        VStack(spacing: 0) {
            DotoNavHeader(title: "Schedule", trailing: {
                AnyView(
                    HStack(spacing: 16) {
                        Button {
                            Task { await vm.previousWeek() }
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Button {
                            Task { await vm.nextWeek() }
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Button {
                            showAddEvent = true
                        } label: {
                            Text("+ Add")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.memberBlue)
                        }
                    }
                )
            })

            WeekStripView(vm: vm)

            Picker("", selection: $viewMode) {
                ForEach(ScheduleViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            if !vm.members.isEmpty {
                avatarFilterRow
                Divider()
            } else {
                Divider()
            }

            if vm.isLoading && vm.events.isEmpty {
                LoadingView()
            } else if viewMode == .weekly {
                weeklyContent
            } else {
                dailyContent
            }
        }
        .background(Color.screenBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await vm.load() }
        .sheet(isPresented: $showAddEvent, onDismiss: { Task { await vm.load() } }) {
            AddEditEventView(event: nil)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event, onUpdate: { Task { await vm.load() } })
        }
        .alert("Something went wrong",
               isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var dailyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(vm.selectedDate.fullDateString)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal)
                    .padding(.top, 12)

                if vm.eventsForSelectedDate.isEmpty {
                    EmptyStateView(
                        message: "No events this day",
                        systemImage: "calendar",
                        cta: "Add one"
                    ) { showAddEvent = true }
                } else {
                    ForEach(vm.eventsForSelectedDate) { event in
                        scheduleEventRow(event)
                            .padding(.horizontal)
                            .onTapGesture { selectedEvent = event }
                    }
                }
            }
            .padding(.bottom, 80)
        }
        .refreshable { await vm.load() }
    }

    private var weeklyContent: some View {
        WeeklyColumnsView(
            vm: vm,
            onSelectDay: { date in
                vm.selectedDate = date
                viewMode = .daily
            },
            onSelectEvent: { event in
                selectedEvent = event
            }
        )
    }

    private var avatarFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(vm.members) { member in
                    Button {
                        vm.toggleMemberFilter(member.id)
                    } label: {
                        AvatarView(
                            name: member.displayName,
                            color: member.color,
                            size: 26,
                            isActive: vm.selectedMemberId == member.id
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    private func scheduleEventRow(_ event: DotoEvent) -> some View {
        let isConflict = event.isConflicting
        let accent = isConflict ? Color.conflictBorder : Color(hex: event.color ?? "#185FA5")
        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 4) {
                Text((isConflict ? "⚠ " : "") + event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isConflict ? .conflictText : .textPrimary)
                Text(subtitleText(event))
                    .font(.system(size: 12))
                    .foregroundColor(isConflict ? .conflictText : .textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isConflict ? Color.conflictBg : Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
    }

    private func subtitleText(_ event: DotoEvent) -> String {
        var parts = ["\(event.startAt.shortTime) · \(event.startAt.duration(to: event.endAt))"]
        if let loc = event.location, !loc.isEmpty { parts.append(loc) }
        if event.isConflicting { parts.append("CONFLICT") }
        return parts.joined(separator: " · ")
    }
}
