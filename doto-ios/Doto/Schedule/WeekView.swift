import SwiftUI

struct WeekView: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly:       Bool
    let currentProfileId: String?

    @State private var selectedEvent: DotoEvent?

    var selectedDayEvents: [DotoEvent] { vm.eventsForDay(vm.selectedDate) }

    var body: some View {
        VStack(spacing: 12) {
            ScheduleWeekStrip(vm: vm, showDots: true)
                .padding(.horizontal, 18)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    ScheduleSelectedDayHeader(date: vm.selectedDate, eventCount: selectedDayEvents.count)

                    if selectedDayEvents.isEmpty {
                        ScheduleEmptyDay()
                    } else {
                        ForEach(selectedDayEvents) { event in
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
