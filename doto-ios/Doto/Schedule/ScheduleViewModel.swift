import Foundation

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var events: [DotoEvent] = []
    @Published var members: [Profile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate: Date = Date()
    @Published var weekOffset: Int = 0
    @Published var selectedMemberId: String? = nil

    var currentWeekStart: Date {
        let base = Calendar.current.date(from: Calendar.current.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: Date()
        ))!
        return Calendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: base)!
    }

    var currentWeekDates: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: currentWeekStart) }
    }

    var eventsForSelectedDate: [DotoEvent] {
        let filtered = events.filter { Calendar.current.isDate($0.startAt, inSameDayAs: selectedDate) }
        if let id = selectedMemberId {
            return filtered.filter { $0.assignedTo.contains(id) }
        }
        return filtered
    }

    func load() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart)!
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = TimeZone(identifier: "UTC")
        let params = [
            "from": fmt.string(from: currentWeekStart),
            "to":   fmt.string(from: weekEnd)
        ]
        do {
            let fetched: [DotoEvent] = try await APIClient.shared.get("/events", params: params)
            events = detectConflicts(fetched)
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
            return
        } catch {
            errorMessage = error.localizedDescription
        }
        if let fam: Family = try? await APIClient.shared.get("/families/mine") {
            members = fam.members
        }
    }

    func previousWeek() async { weekOffset -= 1; await load() }
    func nextWeek()     async { weekOffset += 1; await load() }

    func toggleMemberFilter(_ id: String) {
        selectedMemberId = (selectedMemberId == id) ? nil : id
    }

    private func detectConflicts(_ events: [DotoEvent]) -> [DotoEvent] {
        return events.map { e1 in
            var e = e1
            e.isConflicting = events.contains { e2 in
                e1.id != e2.id &&
                e1.assignedTo.contains(where: e2.assignedTo.contains) &&
                e1.startAt < e2.endAt &&
                e1.endAt   > e2.startAt
            }
            return e
        }
    }
}
