import SwiftUI

struct EventListRow: View {
    let event: DotoEvent

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(event.isConflicting ? Color.conflictBorder : Color(hex: event.color ?? "#185FA5"))
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 2) {
                Text((event.isConflicting ? "⚠ " : "") + event.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(event.isConflicting ? Color.conflictText : Color.textPrimary)

                Text(event.timeRangeLabel)
                    .font(.system(size: 11))
                    .foregroundColor(event.isConflicting ? Color.conflictText.opacity(0.8) : Color.textMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(event.isConflicting ? Color.conflictBg : Color.white)
        .overlay(Divider(), alignment: .bottom)
    }
}
