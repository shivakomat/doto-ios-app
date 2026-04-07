import SwiftUI

struct MonthGridView: View {
    let date:         Date
    let eventsByDay:  [Date: [DotoEvent]]
    @Binding var selectedDate: Date
    let onDoubleTap:  (Date) -> Void

    private let columns   = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var gridDays: [Date?] {
        let cal      = Calendar.current
        let firstDay = date.monthStart
        let weekday  = cal.component(.weekday, from: firstDay) - 1  // 0 = Sun
        let daysInMo = cal.range(of: .day, in: .month, for: firstDay)!.count
        let total    = weekday + daysInMo
        let padded   = total + (7 - total % 7) % 7

        return (0..<padded).map { i in
            i < weekday ? nil
                : cal.date(byAdding: .day, value: i - weekday, to: firstDay)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(dayLabels, id: \.self) { l in
                    Text(l)
                        .font(.system(size: 10))
                        .foregroundColor(Color.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
            .overlay(Divider(), alignment: .bottom)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                    if let day = day {
                        MonthDayCell(
                            day:         day,
                            events:      eventsByDay[day] ?? [],
                            isSelected:  Calendar.current.isDate(day, inSameDayAs: selectedDate),
                            isToday:     Calendar.current.isDateInToday(day),
                            onTap:       { selectedDate = day },
                            onDoubleTap: { onDoubleTap(day) }
                        )
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
    }
}

struct MonthDayCell: View {
    let day:         Date
    let events:      [DotoEvent]
    let isSelected:  Bool
    let isToday:     Bool
    let onTap:       () -> Void
    let onDoubleTap: () -> Void

    var dots: [(color: String, isConflict: Bool)] {
        Array(events.prefix(3).map { e in
            (color: e.color ?? "#185FA5", isConflict: e.isConflicting)
        })
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(Color.memberBlue)
                        .frame(width: 24, height: 24)
                } else if isSelected {
                    Circle()
                        .fill(Color.cardBorder)
                        .frame(width: 24, height: 24)
                }
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.system(size: 11, weight: isToday ? .bold : .regular))
                    .foregroundColor(
                        isToday    ? .white :
                        isSelected ? Color.textPrimary :
                        Color.textSecondary
                    )
            }

            HStack(spacing: 2) {
                ForEach(dots.indices, id: \.self) { i in
                    Circle()
                        .fill(dots[i].isConflict
                            ? Color.conflictBorder
                            : Color(hex: dots[i].color))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 44)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onDoubleTap() }
        .onTapGesture(count: 1) { onTap() }
    }
}
