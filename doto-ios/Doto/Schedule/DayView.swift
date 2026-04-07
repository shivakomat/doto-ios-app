import SwiftUI

struct DayView: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly:       Bool
    let currentProfileId: String?

    @State private var selectedEvent: DotoEvent?

    let hourHeight: CGFloat = 56.0
    let firstHour:  Int     = 7

    var dayEvents: [DotoEvent] { vm.eventsForDay(vm.selectedDate) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(vm.selectedDate.fullDayLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.screenBg)

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    TimeGridView(
                        firstHour:        firstHour,
                        lastHour:         22,
                        hourHeight:       hourHeight,
                        events:           dayEvents,
                        isReadOnly:       isReadOnly,
                        currentProfileId: currentProfileId,
                        onEventTap:       { event in selectedEvent = event }
                    )
                    .padding(.bottom, 80)
                    .id("grid")
                }
                .onAppear {
                    let target = scrollTarget
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation {
                            proxy.scrollTo("grid", anchor: UnitPoint(
                                x: 0,
                                y: CGFloat(target - firstHour) / CGFloat(22 - firstHour)
                            ))
                        }
                    }
                }
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

    private var scrollTarget: Int {
        let cal     = Calendar.current
        let isToday = cal.isDateInToday(vm.selectedDate)
        if isToday {
            return max(firstHour, cal.component(.hour, from: .now) - 1)
        }
        if let first = dayEvents.first {
            return max(firstHour, Int(first.startHour) - 1)
        }
        return 8
    }
}
