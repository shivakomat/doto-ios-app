import SwiftUI

struct WeekView: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly:       Bool
    let currentProfileId: String?

    @State private var selectedEvent: DotoEvent?

    var weekDays: [Date] { vm.daysInWeek(containing: vm.selectedDate) }

    var daysWithEvents: [(day: Date, events: [DotoEvent])] {
        weekDays.compactMap { day in
            let evts = vm.eventsForDay(day)
            return evts.isEmpty ? nil : (day: day, events: evts)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Day-of-week strip
            weekDayStrip
                .background(Color.white)
            Divider()

            // Event list
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if daysWithEvents.isEmpty {
                        Text("No events this week")
                            .font(.system(size: 13))
                            .foregroundColor(Color.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        ForEach(daysWithEvents, id: \.day) { item in
                            let isToday = Calendar.current.isDateInToday(item.day)

                            VStack(alignment: .leading, spacing: 0) {
                                Text(item.day.fullDayLabel)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(isToday ? Color.memberBlue : Color.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.screenBg)

                                Divider()

                                VStack(spacing: 0) {
                                    ForEach(item.events) { event in
                                        EventListRow(event: event)
                                            .onTapGesture { selectedEvent = event }
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
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
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
