import SwiftUI

/// "Wednesday, November 4" heading with an event count, used above Week/Month event lists.
struct ScheduleSelectedDayHeader: View {
    let date: Date
    let eventCount: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(date.fullDayLabel)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Calendar.current.isDateInToday(date) ? .dashBlue : .dashNavy)
            Spacer()
            if eventCount > 0 {
                Text("\(eventCount) event\(eventCount == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.dashSubtle)
            }
        }
    }
}

struct ScheduleEmptyDay: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.dashSubtle)
            Text("No events")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.dashSubtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .dashboardCard()
    }
}
