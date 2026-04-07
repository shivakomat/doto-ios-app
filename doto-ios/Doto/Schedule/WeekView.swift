import SwiftUI

struct WeekView: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly:       Bool
    let currentProfileId: String?

    @State private var selectedEvent: DotoEvent?

    let hourHeight:   CGFloat = 40.0
    let firstHour:    Int     = 7
    let timeColWidth: CGFloat = 28

    var weekDays: [Date] { vm.daysInWeek(containing: vm.selectedDate) }

    var body: some View {
        VStack(spacing: 0) {
            // Day header row
            HStack(spacing: 0) {
                Color.clear.frame(width: timeColWidth)

                ForEach(weekDays, id: \.self) { day in
                    let isToday  = Calendar.current.isDateInToday(day)
                    let isSelect = Calendar.current.isDate(day, inSameDayAs: vm.selectedDate)
                    let dayNum   = Calendar.current.component(.day, from: day)

                    Button {
                        vm.selectedDate = day
                        withAnimation(.easeInOut(duration: 0.2)) { vm.setMode(.day) }
                    } label: {
                        VStack(spacing: 2) {
                            Text(day.shortWeekdayLabel)
                                .font(.system(size: 9))
                                .foregroundColor(isToday ? Color.memberBlue : Color.textMuted)

                            ZStack {
                                if isToday {
                                    Circle().fill(Color.memberBlue).frame(width: 20, height: 20)
                                } else if isSelect {
                                    Circle().fill(Color.cardBorder).frame(width: 20, height: 20)
                                }
                                Text("\(dayNum)")
                                    .font(.system(size: 10, weight: isToday ? .bold : .regular))
                                    .foregroundColor(isToday ? .white : Color.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .background(isToday ? Color.memberBlue.opacity(0.05) : Color.clear)
                }
            }
            .background(Color.white)
            .overlay(Divider(), alignment: .bottom)

            // Scrollable time grid with 7 columns
            ScrollView(.vertical, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Time labels
                    VStack(spacing: 0) {
                        ForEach(firstHour..<22, id: \.self) { hour in
                            Text(hourLabelShort(hour))
                                .font(.system(size: 9))
                                .foregroundColor(isNowHour(hour) ? Color(hex: "#E24B4A") : Color.textMuted)
                                .frame(width: timeColWidth, height: hourHeight, alignment: .topTrailing)
                                .padding(.trailing, 4)
                        }
                    }

                    // 7 day columns
                    ForEach(weekDays, id: \.self) { day in
                        WeekDayColumn(
                            day:        day,
                            events:     vm.eventsForDay(day),
                            hourHeight: hourHeight,
                            firstHour:  firstHour,
                            isReadOnly: isReadOnly,
                            onEventTap: { event in
                                vm.selectedDate = day
                                selectedEvent   = event
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .overlay(Divider(), alignment: .leading)
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

    func hourLabelShort(_ hour: Int) -> String {
        if hour == 12 { return "12" }
        return hour < 12 ? "\(hour)" : "\(hour - 12)"
    }

    func isNowHour(_ hour: Int) -> Bool {
        Calendar.current.component(.hour, from: .now) == hour
    }
}

struct WeekDayColumn: View {
    let day:        Date
    let events:     [DotoEvent]
    let hourHeight: CGFloat
    let firstHour:  Int
    let isReadOnly: Bool
    let onEventTap: (DotoEvent) -> Void

    var isToday: Bool { Calendar.current.isDateInToday(day) }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                ForEach(firstHour..<22, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: hourHeight)
                        .overlay(Divider(), alignment: .bottom)
                }
            }

            if isToday { Color.memberBlue.opacity(0.03) }

            ForEach(events) { event in
                let topOffset = CGFloat(event.startHour - Double(firstHour)) * hourHeight
                let height    = max(hourHeight * CGFloat(event.durationHours), 18)
                EventBlock(
                    event:      event,
                    isReadOnly: isReadOnly,
                    isDimmed:   false,
                    onTap:      { onEventTap(event) }
                )
                .frame(height: height)
                .offset(y: topOffset)
            }

            if isToday {
                NowLine(hourHeight: hourHeight, firstHour: firstHour)
            }
        }
    }
}
