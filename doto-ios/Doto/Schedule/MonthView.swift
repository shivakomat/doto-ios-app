import SwiftUI

struct MonthView: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly: Bool

    @State private var selectedEvent: DotoEvent?

    var body: some View {
        let dayEvents = vm.eventsForDay(vm.selectedDate)

        VStack(spacing: 12) {
            MonthGridView(
                date:        vm.selectedDate,
                eventsByDay: vm.eventsForMonth(containing: vm.selectedDate),
                selectedDate: Binding(
                    get: { vm.selectedDate },
                    set: { vm.selectedDate = $0 }
                ),
                onDoubleTap: { date in
                    vm.selectedDate = date
                    withAnimation(.easeOut(duration: 0.3)) { vm.setMode(.week) }
                }
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .dashboardCard()
            .padding(.horizontal, 18)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    ScheduleSelectedDayHeader(date: vm.selectedDate, eventCount: dayEvents.count)

                    if dayEvents.isEmpty {
                        ScheduleEmptyDay()
                    } else {
                        ForEach(dayEvents) { event in
                            EventListRow(event: event)
                                .onTapGesture { selectedEvent = event }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
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
}
