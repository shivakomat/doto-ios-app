import SwiftUI

struct EventReadOnlySheet: View {
    let event:   DotoEvent
    let members: [Profile]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color.cardBorder)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: event.color ?? "#185FA5"))
                        .frame(width: 10, height: 10)
                        .padding(.top, 3)
                    Text(event.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                }
                Spacer()
                Button("Close") { dismiss() }
                    .font(.system(size: 13))
                    .foregroundColor(Color.memberBlue)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            VStack(spacing: 14) {
                DetailInfoRow(icon: "clock",
                    text: "\(event.startAt.fullDayLabel)\n\(event.timeRangeLabel) · \(event.durationMinutes) min")
                if let loc = event.location, !loc.isEmpty {
                    DetailInfoRow(icon: "mappin", text: loc)
                }
                if let rep = event.repeat_, rep != "none" {
                    DetailInfoRow(icon: "repeat", text: rep.capitalized)
                }
                if let notes = event.description, !notes.isEmpty {
                    DetailInfoRow(icon: "note.text", text: notes)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            if event.isConflicting {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.conflictBorder)
                    Text("Scheduling conflict")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.conflictText)
                }
                .padding(12)
                .background(Color.conflictBg)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.conflictBorder, lineWidth: 1))
                .cornerRadius(8)
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            Spacer()
        }
        .presentationDetents([.medium, .large])
    }
}

struct DetailInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(Color.textMuted)
                .frame(width: 18)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
