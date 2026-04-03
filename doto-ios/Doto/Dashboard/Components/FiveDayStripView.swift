import SwiftUI

struct FiveDayStripView: View {
    let days: [DashboardDay]
    @Binding var selectedIndex: Int
    let members: [FamilyMemberSummary]

    var body: some View {
        VStack(spacing: 0) {
            // Day selector header
            HStack(spacing: 0) {
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
                    if index < days.count - 1 {
                        Divider().frame(height: 50)
                    }
                }
            }
            .background(Color.white)

            // Expanded events for selected day
            if selectedIndex >= 0, let day = days[safe: selectedIndex] {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text(fullDayLabel(day))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.textMuted)
                        .padding(.horizontal, 10)
                        .padding(.top, 8)

                    if day.events.isEmpty {
                        Text("No events")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 8)
                    } else {
                        ForEach(day.events.prefix(3)) { event in
                            DashboardEventRow(event: event, members: members)
                                .padding(.horizontal, 10)
                        }
                        if day.events.count > 3 {
                            HStack {
                                Spacer()
                                NavigationLink("+ \(day.events.count - 3) more → See all") {
                                    // Navigate to Schedule tab with this day selected
                                }
                                .font(.system(size: 11))
                                .foregroundColor(.memberBlue)
                            }
                            .padding(.horizontal, 10)
                        }
                        Spacer().frame(height: 8)
                    }
                }
                .background(Color.white)
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
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
            VStack(spacing: 3) {
                Text(day.dayLabel)
                    .font(.system(size: 8, weight: isSelected ? .bold : .regular))
                    .foregroundColor(day.isToday ? .memberBlue : .textMuted)

                // Date circle
                ZStack {
                    Circle()
                        .fill(day.isToday ? Color.memberBlue : Color.clear)
                        .frame(width: 22, height: 22)
                    Text(day.dayNumber)
                        .font(.system(size: 11, weight: day.isToday ? .bold : .regular))
                        .foregroundColor(day.isToday ? .white : .textSecondary)
                }

                // Event dots
                HStack(spacing: 2) {
                    ForEach(day.memberColors.prefix(3), id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.selectedDayBg : Color.clear)
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
