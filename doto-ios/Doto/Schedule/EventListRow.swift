import SwiftUI

/// Tinted rounded event card used by the Week and Month lists.
struct EventListRow: View {
    let event: DotoEvent

    private var accent: Color {
        event.isConflicting ? .conflictBorder : Color(hex: event.color ?? "#185FA5")
    }

    var body: some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(accent)
                .frame(width: 4, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text((event.isConflicting ? "⚠ " : "") + event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(event.isConflicting ? .conflictText : .dashNavy)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(event.isConflicting ? Color.conflictText.opacity(0.8) : .dashSubtle)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            ZStack {
                Color.white
                (event.isConflicting ? Color.conflictBg : accent.opacity(0.12))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent.opacity(0.25), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        if let loc = event.location, !loc.isEmpty {
            return "\(event.timeRangeLabel) · \(loc)"
        }
        return event.timeRangeLabel
    }
}
