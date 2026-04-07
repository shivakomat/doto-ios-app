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
}
