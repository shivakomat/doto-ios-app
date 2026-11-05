import SwiftUI

struct EventReadOnlySheet: View {
    let event:   DotoEvent
    let members: [Profile]

    @Environment(\.dismiss) private var dismiss

    private var accent: Color { Color(hex: event.color ?? "#185FA5") }

    var body: some View {
        ZStack {
            DashboardBackground(showLandscape: false)

            VStack(alignment: .leading, spacing: 16) {
                Capsule()
                    .fill(Color.dashCardBorder)
                    .frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        Capsule().fill(accent).frame(width: 5, height: 28)
                        Text(event.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.dashNavy)
                    }
                    Spacer()
                    Button("Close") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.dashBlue)
                }

                VStack(alignment: .leading, spacing: 16) {
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
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .dashboardCard(radius: 16)

                if event.isConflicting {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color.conflictBorder)
                        Text("Scheduling conflict")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.conflictText)
                        Spacer()
                    }
                    .padding(12)
                    .dashboardCard(radius: 14, fill: .conflictBg, border: .conflictBorder)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
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
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.dashBlue)
                .frame(width: 32, height: 32)
                .background(Color.dashBlueTint)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.dashNavy)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
    }
}
