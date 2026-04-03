import SwiftUI

struct ChildEventsSection: View {
    let events: [DashboardEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming events")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textPrimary)

            VStack(spacing: 0) {
                ForEach(events) { event in
                    ChildEventRow(event: event)
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
        }
    }
}

struct ChildEventRow: View {
    let event: DashboardEvent

    var body: some View {
        HStack(spacing: 10) {
            // Accent bar
            Rectangle()
                .fill(event.isConflicting ? Color.conflictBorder : Color.memberBlue)
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(event.isConflicting ? .conflictText : .textPrimary)

                HStack(spacing: 4) {
                    Text(event.startAt.shortTime)
                        .font(.system(size: 10))
                        .foregroundColor(.textSecondary)
                    if let loc = event.location {
                        Text("· \(loc)")
                            .font(.system(size: 10))
                            .foregroundColor(.textMuted)
                    }
                    if event.isConflicting {
                        Text("· CONFLICT")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.conflictText)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(event.isConflicting ? Color.conflictBg : Color.clear)
        .overlay(Divider().frame(maxWidth: .infinity), alignment: .bottom)
    }
}
