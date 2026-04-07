import SwiftUI

struct TimeGridView: View {
    let firstHour:        Int
    let lastHour:         Int
    let hourHeight:       CGFloat
    let events:           [DotoEvent]
    let isReadOnly:       Bool
    let currentProfileId: String?
    let onEventTap:       (DotoEvent) -> Void

    private let timeColWidth: CGFloat = 40

    var body: some View {
        GeometryReader { geo in
            let colWidth    = geo.size.width - timeColWidth
            let totalHeight = CGFloat(lastHour - firstHour) * hourHeight

            ZStack(alignment: .topLeading) {
                // Hour rows
                VStack(spacing: 0) {
                    ForEach(firstHour..<lastHour, id: \.self) { hour in
                        HStack(spacing: 0) {
                            Text(hourLabel(hour))
                                .font(.system(size: 10))
                                .foregroundColor(isNowHour(hour)
                                    ? Color(hex: "#E24B4A")
                                    : Color.textMuted)
                                .frame(width: timeColWidth, alignment: .trailing)
                                .padding(.trailing, 6)

                            Rectangle()
                                .fill(Color.cardBorder)
                                .frame(height: 0.5)
                        }
                        .frame(height: hourHeight)
                    }
                }

                // Event blocks
                ForEach(layoutGroups(), id: \.id) { item in
                    EventBlock(
                        event:      item.event,
                        isReadOnly: isReadOnly,
                        isDimmed:   shouldDim(item.event),
                        onTap:      { onEventTap(item.event) }
                    )
                    .frame(
                        width:  colWidth * item.widthFraction - 2,
                        height: max(hourHeight * CGFloat(item.event.durationHours), 20)
                    )
                    .offset(
                        x: timeColWidth + colWidth * item.xFraction + 1,
                        y: yOffset(for: item.event)
                    )
                }

                // Now line (today only)
                if Calendar.current.isDateInToday(Date()) {
                    NowLine(hourHeight: hourHeight, firstHour: firstHour)
                        .offset(x: timeColWidth, y: 0)
                        .frame(width: colWidth)
                }
            }
            .frame(height: totalHeight)
        }
        .frame(height: CGFloat(lastHour - firstHour) * hourHeight)
    }

    // MARK: - Layout

    struct LayoutItem: Identifiable {
        let id:            String
        let event:         DotoEvent
        let xFraction:     CGFloat
        let widthFraction: CGFloat
    }

    func layoutGroups() -> [LayoutItem] {
        var result:    [LayoutItem] = []
        var remaining = events.sorted { $0.startAt < $1.startAt }

        while !remaining.isEmpty {
            let event   = remaining.removeFirst()
            var cluster = [event]

            var i = 0
            while i < remaining.count {
                let candidate = remaining[i]
                let overlaps  = cluster.contains { e in
                    e.startAt < candidate.endAt && e.endAt > candidate.startAt
                }
                if overlaps {
                    cluster.append(remaining.remove(at: i))
                } else {
                    i += 1
                }
            }

            let cols = cluster.count
            for (index, e) in cluster.enumerated() {
                result.append(LayoutItem(
                    id:            e.id,
                    event:         e,
                    xFraction:     CGFloat(index) / CGFloat(cols),
                    widthFraction: 1.0 / CGFloat(cols)
                ))
            }
        }
        return result
    }

    func yOffset(for event: DotoEvent) -> CGFloat {
        CGFloat(event.startHour - Double(firstHour)) * hourHeight
    }

    func shouldDim(_ event: DotoEvent) -> Bool {
        guard let id = currentProfileId else { return false }
        return !event.assignedTo.contains(id)
    }

    func hourLabel(_ hour: Int) -> String {
        if hour == 12 { return "12 PM" }
        if hour == 0  { return "12 AM" }
        return hour < 12 ? "\(hour) AM" : "\(hour - 12) PM"
    }

    func isNowHour(_ hour: Int) -> Bool {
        Calendar.current.component(.hour, from: .now) == hour
    }
}
