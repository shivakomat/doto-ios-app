import SwiftUI

struct EventDetailSheet: View {
    let event: DotoEvent
    var onUpdate: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @EnvironmentObject var authVM: AuthViewModel

    private var accent: Color { Color(hex: event.color ?? "#185FA5") }

    var body: some View {
        NavigationView {
            ZStack {
                DashboardBackground(showLandscape: false)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 10) {
                            Capsule().fill(accent).frame(width: 5, height: 30)
                            Text(event.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.dashNavy)
                        }

                        if event.isConflicting {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.conflictText)
                                Text("Conflicts with another event")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.conflictText)
                                Spacer()
                            }
                            .padding(12)
                            .dashboardCard(radius: 14, fill: .conflictBg, border: .conflictBorder)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            DetailInfoRow(icon: "calendar", text: event.startAt.fullDayLabel)
                            DetailInfoRow(icon: "clock",
                                          text: "\(event.startAt.shortTime) – \(event.endAt.shortTime) · \(event.startAt.duration(to: event.endAt))")
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if authVM.currentProfile?.isParent == true {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") { showEdit = true }
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .tint(.dashBlue)
        .sheet(isPresented: $showEdit, onDismiss: { onUpdate?(); dismiss() }) {
            AddEditEventView(event: event)
        }
    }
}
