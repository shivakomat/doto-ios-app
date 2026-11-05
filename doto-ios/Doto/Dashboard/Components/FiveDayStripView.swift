import SwiftUI

struct FiveDayStripView: View {
    let days: [DashboardDay]
    @Binding var selectedIndex: Int
    let members: [FamilyMemberSummary]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    DayColumn(
                        day: day,
                        isSelected: index == selectedIndex,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedIndex = selectedIndex == index ? -1 : index
                            }
                        }
                    )
                }
            }

            // Events for the selected day (only when there is something to show)
            if selectedIndex >= 0, let day = days[safe: selectedIndex], !day.events.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(fullDayLabel(day))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.dashSubtle)

                    ForEach(day.events.prefix(3)) { event in
                        DashboardEventRow(event: event, members: members)
                    }
                    if day.events.count > 3 {
                        Text("+ \(day.events.count - 3) more")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.dashBlue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .dashboardCard()
            }
        }
    }

    private func fullDayLabel(_ day: DashboardDay) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: day.date) else { return day.dayLabel }
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

struct DayColumn: View {
    let day: DashboardDay
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(day.isToday ? "Today" : day.dayLabel)
                    .font(.system(size: 11, weight: day.isToday ? .bold : .medium))
                    .foregroundColor(day.isToday ? .dashBlue : .dashSubtle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                ZStack {
                    Circle()
                        .fill(day.isToday ? Color.dashBlue : Color.clear)
                        .frame(width: 28, height: 28)
                    Text(day.dayNumber)
                        .font(.system(size: 15, weight: day.isToday ? .bold : .semibold))
                        .foregroundColor(day.isToday ? .white : .dashNavy)
                }

                HStack(spacing: 3) {
                    ForEach(Array(day.memberColors.prefix(3).enumerated()), id: \.offset) { _, hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(day.isToday ? Color.dashBlueTint : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        day.isToday || isSelected ? Color.dashBlueBorder : Color.dashCardBorder,
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.dashNavy.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct DashboardEventRow: View {
    let event: DashboardEvent
    let members: [FamilyMemberSummary]

    private var assigneeColor: String {
        event.assignedTo.first.flatMap { id in
            members.first { $0.id == id }?.color
        } ?? "#94A3B8"
    }

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(event.isConflicting ? Color.conflictBorder : Color(hex: assigneeColor))
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 2) {
                Text((event.isConflicting ? "⚠ " : "") + event.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(event.isConflicting ? .conflictText : Color(hex: assigneeColor))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(event.startAt.shortTime)
                    if let loc = event.location {
                        Text("· \(loc)")
                    }
                    if event.isConflicting {
                        Text("· CONFLICT")
                            .fontWeight(.semibold)
                    }
                }
                .font(.system(size: 9))
                .foregroundColor(event.isConflicting ? .conflictText.opacity(0.8) : .textMuted)
            }

            Spacer()
        }
        .padding(8)
        .background(
            event.isConflicting
                ? Color.conflictBg
                : Color(hex: assigneeColor).opacity(0.08)
        )
        .cornerRadius(6)
    }
}
