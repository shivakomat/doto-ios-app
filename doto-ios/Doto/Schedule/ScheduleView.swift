import SwiftUI

enum ScheduleViewMode: String, CaseIterable {
    case daily   = "Daily"
    case weekly  = "Weekly"
    case monthly = "Monthly"
}

struct ScheduleView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ScheduleViewModel()

    @State private var viewMode: ScheduleViewMode = .daily
    @State private var showAddEvent = false
    @State private var selectedEvent: DotoEvent?

    private var isChild: Bool { authVM.currentProfile?.isChild == true }

    var body: some View {
        VStack(spacing: 0) {
            DotoNavHeader(title: "Schedule", trailing: {
                AnyView(
                    HStack(spacing: 16) {
                        Button {
                            Task {
                                if viewMode == .monthly {
                                    await vm.previousMonth()
                                } else {
                                    await vm.previousWeek()
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Button {
                            Task {
                                if viewMode == .monthly {
                                    await vm.nextMonth()
                                } else {
                                    await vm.nextWeek()
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        if !isChild {
                            Button {
                                showAddEvent = true
                            } label: {
                                Text("+ Add")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.memberBlue)
                            }
                        }
                    }
                )
            })

            if viewMode == .monthly {
                Text(vm.currentMonthLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.vertical, 10)
            } else {
                WeekStripView(vm: vm)
            }

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

            if vm.isLoading && (viewMode == .monthly ? vm.monthEvents.isEmpty : vm.events.isEmpty) {
                LoadingView()
            } else if viewMode == .monthly {
                monthlyContent
            } else if viewMode == .weekly {
                weeklyContent
            } else {
                dailyContent
            }
        }
        .background(Color.screenBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await vm.load() }
        .onChange(of: viewMode) { newMode in
            if newMode == .monthly && vm.monthEvents.isEmpty {
                Task { await vm.loadMonth() }
            }
        }
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
                        cta: isChild ? nil : "Add one"
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(vm.currentWeekDates, id: \.self) { date in
                    let dayEvents = vm.eventsForDate(date)
                    let isToday = Calendar.current.isDateInToday(date)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(date.fullDateString)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isToday ? .memberBlue : .textPrimary)

                        if dayEvents.isEmpty {
                            Text("No events")
                                .font(.system(size: 12))
                                .foregroundColor(.textMuted)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(dayEvents) { event in
                                scheduleEventRow(event)
                                    .onTapGesture { selectedEvent = event }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 80)
        }
        .refreshable { await vm.load() }
    }

    private var monthlyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(vm.currentMonthWeeks.enumerated()), id: \.offset) { _, week in
                    VStack(alignment: .leading, spacing: 12) {
                        let weekLabel = weekHeaderLabel(week)
                        Text(weekLabel)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textSecondary)
                            .padding(.bottom, 2)

                        ForEach(week, id: \.self) { date in
                            let dayEvents = vm.eventsForDateInMonth(date)
                            let isToday = Calendar.current.isDateInToday(date)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(date.fullDateString)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(isToday ? .memberBlue : .textPrimary)

                                if dayEvents.isEmpty {
                                    Text("No events")
                                        .font(.system(size: 12))
                                        .foregroundColor(.textMuted)
                                        .padding(.vertical, 2)
                                } else {
                                    ForEach(dayEvents) { event in
                                        scheduleEventRow(event)
                                            .onTapGesture { selectedEvent = event }
                                    }
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 80)
        }
        .refreshable { await vm.loadMonth() }
    }

    private func weekHeaderLabel(_ week: [Date]) -> String {
        guard let first = week.first, let last = week.last else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        if first == last {
            return "Week of \(fmt.string(from: first))"
        }
        return "\(fmt.string(from: first)) – \(fmt.string(from: last))"
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
