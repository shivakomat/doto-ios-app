import SwiftUI

struct MonthView: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly: Bool

    @State private var selectedEvent: DotoEvent?

    var body: some View {
        VStack(spacing: 0) {
            MonthGridView(
                date:        vm.selectedDate,
                eventsByDay: vm.eventsForMonth(containing: vm.selectedDate),
                selectedDate: Binding(
                    get: { vm.selectedDate },
                    set: { vm.selectedDate = $0 }
                ),
                onDoubleTap: { date in
                    vm.selectedDate = date
                    withAnimation(.easeOut(duration: 0.3)) { vm.setMode(.day) }
                }
            )
            .background(Color.white)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
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

                    let dayEvents = vm.eventsForDay(vm.selectedDate)
                    if dayEvents.isEmpty {
                        Text("No events")
                            .font(.system(size: 13))
                            .foregroundColor(Color.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 20)
                    } else {
                        ForEach(dayEvents) { event in
                            EventListRow(event: event)
                                .onTapGesture { selectedEvent = event }
                        }
                    }
                }
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
}
