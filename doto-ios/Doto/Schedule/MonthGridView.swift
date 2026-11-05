import SwiftUI

struct MonthGridView: View {
    let date:         Date
    let eventsByDay:  [Date: [DotoEvent]]
    @Binding var selectedDate: Date
    let onDoubleTap:  (Date) -> Void

    private let columns   = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

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
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(dayLabels, id: \.self) { l in
                    Text(l)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.dashSubtle)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 2) {
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
                        Color.clear.frame(height: 46)
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
                if isSelected {
                    Circle()
                        .fill(Color.dashBlue)
                        .frame(width: 30, height: 30)
                } else if isToday {
                    Circle()
                        .fill(Color.dashBlueTint)
                        .frame(width: 30, height: 30)
                }
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.system(size: 15, weight: isSelected || isToday ? .bold : .medium))
                    .foregroundColor(
                        isSelected ? .white :
                        isToday    ? .dashBlue :
                        .dashNavy
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
        .frame(height: 46)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onDoubleTap() }
        .onTapGesture(count: 1) { onTap() }
    }
}
