import SwiftUI

/// Searches the events currently loaded for the visible month (title or location).
struct ScheduleSearchSheet: View {
    @ObservedObject var vm: ScheduleViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @FocusState private var focused: Bool

    private var results: [DotoEvent] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return vm.events
            .filter { $0.title.lowercased().contains(q) || ($0.location?.lowercased().contains(q) ?? false) }
            .sorted { $0.startAt < $1.startAt }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.dashSubtle)
                    TextField("Search events", text: $query)
                        .focused($focused)
                        .submitLabel(.search)
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.textMuted)
                        }
                    }
                }
                .padding(12)
                .background(Color(hex: "#EEF2F9"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(16)

                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    Spacer()
                    Text("Search by event title or location")
                        .font(.system(size: 14)).foregroundColor(.dashSubtle)
                    Spacer()
                } else if results.isEmpty {
                    Spacer()
                    Text("No events found").font(.system(size: 14)).foregroundColor(.dashSubtle)
                    Spacer()
                } else {
                    List(results) { event in
                        Button {
                            vm.selectedDate = event.startAt
                            vm.setMode(.week)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.dashNavy)
                                Text("\(event.startAt.fullDayLabel) · \(event.timeRangeLabel)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.dashSubtle)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .onAppear { focused = true }
        }
    }
}
