import SwiftUI

struct EventDetailSheet: View {
    let event: DotoEvent
    var onUpdate: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if event.isConflicting {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.conflictText)
                            Text("Conflicts with another event")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.conflictText)
                        }
                        .padding(10)
                        .background(Color.conflictBg)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.conflictBorder, lineWidth: 1))
                        .cornerRadius(6)
                        .padding(.horizontal)
                    }

                    detailRow(label: "Date", value: event.startAt.shortDate)
                    detailRow(label: "Time", value: "\(event.startAt.shortTime) – \(event.endAt.shortTime) · \(event.startAt.duration(to: event.endAt))")
                    if let loc = event.location, !loc.isEmpty {
                        detailRow(label: "Location", value: loc)
                    }
                    if let rep = event.repeat_, rep != "none" {
                        detailRow(label: "Repeat", value: rep.capitalized)
                    }
                    if let notes = event.description, !notes.isEmpty {
                        detailRow(label: "Notes", value: notes)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(event.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if authVM.currentProfile?.isParent == true {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") { showEdit = true }
                    }
                }
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: { onUpdate?(); dismiss() }) {
            AddEditEventView(event: event)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.textMuted)
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal)
    }
}
