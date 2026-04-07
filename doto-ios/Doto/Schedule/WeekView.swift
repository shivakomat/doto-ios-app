import SwiftUI

struct WeekView: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly:       Bool
    let currentProfileId: String?

    @State private var selectedEvent: DotoEvent?

    var weekDays: [Date] { vm.daysInWeek(containing: vm.selectedDate) }

    var selectedDayEvents: [DotoEvent] { vm.eventsForDay(vm.selectedDate) }

    var body: some View {
        VStack(spacing: 0) {
            // Day-of-week strip
            weekDayStrip
                .background(Color.white)
            Divider()

            // Selected day label
            HStack {
                Text(vm.selectedDate.fullDayLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Calendar.current.isDateInToday(vm.selectedDate) ? Color.memberBlue : Color.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.screenBg)

            Divider()

            // Event list for selected day only
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if selectedDayEvents.isEmpty {
                        Text("No events")
                            .font(.system(size: 13))
                            .foregroundColor(Color.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        ForEach(selectedDayEvents) { event in
                            EventListRow(event: event)
                                .onTapGesture { selectedEvent = event }
                        }
                    }
                }
                .background(Color.white)
                .padding(.bottom, 80)
            }
            .refreshable { await vm.load(monthStart: vm.selectedDate.monthStart) }
        }
        .sheet(item: $selectedEvent) { event in
            if isReadOnly {
                EventReadOnlySheet(event: event, members: vm.members)
            } else {
                EventDetailSheet(event: event, onUpdate: {
                    Task { await vm.load(monthStart: vm.selectedDate.monthStart) }
                })
            }
        }
    }

    private static let weekdayFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f
    }()

    private var weekDayStrip: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                let isToday  = Calendar.current.isDateInToday(day)
                let isSelect = Calendar.current.isDate(day, inSameDayAs: vm.selectedDate)
                let dayNum   = Calendar.current.component(.day, from: day)
                let letter   = String(Self.weekdayFmt.string(from: day).prefix(1))

                let dayEvents = vm.eventsForDay(day)
                let dots      = Array(dayEvents.prefix(3))

                Button {
                    vm.selectedDate = day
                } label: {
                    VStack(spacing: 3) {
                        Text(letter)
                            .font(.system(size: 10))
                            .foregroundColor(isToday ? Color.memberBlue : Color.textMuted)

                        ZStack {
                            if isToday {
                                Circle().fill(Color.memberBlue).frame(width: 24, height: 24)
                            } else if isSelect {
                                Circle().fill(Color.cardBorder).frame(width: 24, height: 24)
                            }
                            Text("\(dayNum)")
                                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                                .foregroundColor(isToday ? .white : isSelect ? Color.textPrimary : Color.textSecondary)
                        }

                        HStack(spacing: 2) {
                            ForEach(dots.indices, id: \.self) { i in
                                Circle()
                                    .fill(dots[i].isConflicting
                                        ? Color.conflictBorder
                                        : Color(hex: dots[i].color ?? "#185FA5"))
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .frame(height: 6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
