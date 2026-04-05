import SwiftUI

struct WeeklyColumnsView: View {
    @ObservedObject var vm: ScheduleViewModel
    let onSelectDay: (Date) -> Void
    let onSelectEvent: (DotoEvent) -> Void

    private let columnWidth: CGFloat = (UIScreen.main.bounds.width - 32) / 3.5

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(vm.currentWeekDates, id: \.self) { date in
                    dayColumn(date: date)
                        .frame(width: columnWidth)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func dayColumn(date: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(date)
        let dayEvents = vm.eventsForDate(date)
        let dayNum = Calendar.current.component(.day, from: date)
        let dayName = date.abbreviated

        VStack(spacing: 0) {
            Button {
                onSelectDay(date)
            } label: {
                VStack(spacing: 3) {
                    Text(dayName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isToday ? .white : .textSecondary)
                    Text("\(dayNum)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isToday ? .white : .textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isToday ? Color.memberBlue : Color.clear)
            }
            .buttonStyle(.plain)

            Divider()

            VStack(spacing: 6) {
                if dayEvents.isEmpty {
                    Text("—")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                        .frame(maxWidth: .infinity, minHeight: 40)
                } else {
                    ForEach(dayEvents) { event in
                        eventCard(event)
                            .onTapGesture { onSelectEvent(event) }
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
        }
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.01))
                .overlay(
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(Color(hex: "#E2E8F0")),
                    alignment: .trailing
                )
        )
    }

    @ViewBuilder
    private func eventCard(_ event: DotoEvent) -> some View {
        let isConflict = event.isConflicting
        let accent = isConflict ? Color.conflictBorder : Color(hex: event.color ?? "#185FA5")
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(accent)
                .frame(width: 2.5)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isConflict ? .conflictText : .textPrimary)
                    .lineLimit(2)
                Text(event.startAt.shortTime)
                    .font(.system(size: 9))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isConflict ? Color.conflictBg : accent.opacity(0.08))
        .cornerRadius(6)
    }
}

private extension Date {
    var abbreviated: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: self)
    }
}
