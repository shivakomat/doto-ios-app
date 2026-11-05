import SwiftUI

struct ChildEventsSection: View {
    let events: [DashboardEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DashboardSectionHeader(title: "Upcoming events")

            VStack(spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { idx, event in
                    ChildEventRow(event: event, showDivider: idx < events.count - 1)
                }
            }
            .dashboardCard()
        }
    }
}

struct ChildEventRow: View {
    let event: DashboardEvent
    var showDivider: Bool = true

    private var accent: Color { event.isConflicting ? .conflictBorder : .dashBlue }

    var body: some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(accent)
                .frame(width: 4, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(event.isConflicting ? .conflictText : .dashNavy)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(event.startAt.shortTime)
                    if let loc = event.location {
                        Text("· \(loc)")
                    }
                    if event.isConflicting {
                        Text("· CONFLICT").fontWeight(.semibold)
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(event.isConflicting ? .conflictText.opacity(0.8) : .dashSubtle)
                .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(event.isConflicting ? Color.conflictBg : Color.clear)
        .overlay(alignment: .bottom) {
            if showDivider {
                Rectangle().fill(Color.dashCardBorder).frame(height: 1).padding(.horizontal, 14)
            }
        }
    }
}
