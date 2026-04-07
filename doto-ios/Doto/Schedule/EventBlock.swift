import SwiftUI

struct EventBlock: View {
    let event:      DotoEvent
    let isReadOnly: Bool
    let isDimmed:   Bool
    let onTap:      () -> Void

    var accentColor: Color {
        event.isConflicting
            ? Color.conflictBorder
            : Color(hex: event.color ?? "#185FA5")
    }

    var bgColor: Color {
        event.isConflicting ? Color.conflictBg : accentColor.opacity(0.1)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 1) {
                    Text((event.isConflicting ? "⚠ " : "") + event.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(event.isConflicting ? Color.conflictText : accentColor)
                        .lineLimit(2)

                    if event.durationMinutes > 30 {
                        Text(event.timeRangeLabel)
                            .font(.system(size: 8))
                            .foregroundColor(event.isConflicting
                                ? Color.conflictText.opacity(0.8)
                                : Color.textMuted)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)

                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .background(bgColor)
        .overlay(
            event.isConflicting
                ? AnyView(RoundedRectangle(cornerRadius: 4).stroke(Color.conflictBorder, lineWidth: 1))
                : AnyView(EmptyView())
        )
        .cornerRadius(4)
        .opacity(isDimmed ? 0.5 : 1.0)
    }
}
