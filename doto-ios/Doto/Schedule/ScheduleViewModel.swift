import Foundation

enum ScheduleMode: String, CaseIterable {
    case day   = "Day"
    case week  = "Week"
    case month = "Month"
}

@MainActor
class ScheduleViewModel: ObservableObject {

    @Published var selectedDate: Date = .now
    @Published var viewMode: ScheduleMode = .day
    @Published var events: [DotoEvent] = []
    @Published var members: [Profile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var activeFilterMemberId: String?

    private var loadedMonthStart: Date?
    private let modeKey = "scheduleViewMode"

    init() {
        if let saved = UserDefaults.standard.string(forKey: modeKey),
           let mode = ScheduleMode(rawValue: saved) {
            viewMode = mode
        }
    }

    func setMode(_ mode: ScheduleMode) {
        viewMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: modeKey)
    }

    // MARK: - Data fetching

    func loadIfNeeded(for date: Date) async {
        let monthStart = date.monthStart
        if loadedMonthStart == monthStart && !events.isEmpty { return }
        await load(monthStart: monthStart)
    }

    func load(monthStart: Date) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        let monthEnd = Calendar.current.date(
            byAdding: DateComponents(month: 1, day: -1), to: monthStart
        )!

        let fmt = ISO8601DateFormatter()
        fmt.timeZone = .current
        let from = fmt.string(from: monthStart)
        let to   = fmt.string(from: monthEnd)

        do {
            var fetched: [DotoEvent] = try await APIClient.shared.get(
                "/events", params: ["from": from, "to": to]
            )
            fetched = detectConflicts(fetched)
            events = fetched
            loadedMonthStart = monthStart
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
            return
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }

        if members.isEmpty {
            if let fam: Family = try? await APIClient.shared.get("/families/mine") {
                members = fam.members
            }
        }
    }

    // MARK: - Events for ranges

    func eventsForDay(_ date: Date) -> [DotoEvent] {
        let cal = Calendar.current
        return events
            .filter { cal.isDate($0.startAt, inSameDayAs: date) }
            .filter { memberFilter($0) }
            .sorted { $0.startAt < $1.startAt }
    }

    func eventsForMonth(containing date: Date) -> [Date: [DotoEvent]] {
        let days = daysInMonth(containing: date)
        return Dictionary(uniqueKeysWithValues: days.map { day in
            (day, eventsForDay(day))
        })
    }

    // MARK: - Member filter

    private func memberFilter(_ event: DotoEvent) -> Bool {
        guard let filterId = activeFilterMemberId else { return true }
        return event.assignedTo.contains(filterId)
    }

    func toggleMemberFilter(id: String) {
        activeFilterMemberId = activeFilterMemberId == id ? nil : id
    }

    // MARK: - Navigation

    func navigateForward() {
        let cal = Calendar.current
        switch viewMode {
        case .day:   selectedDate = cal.date(byAdding: .day,   value:  1, to: selectedDate)!
        case .week:  selectedDate = cal.date(byAdding: .day,   value:  7, to: selectedDate)!
        case .month: selectedDate = cal.date(byAdding: .month, value:  1, to: selectedDate)!
        }
        Task { await loadIfNeeded(for: selectedDate) }
    }

    func navigateBack() {
        let cal = Calendar.current
        switch viewMode {
        case .day:   selectedDate = cal.date(byAdding: .day,   value: -1, to: selectedDate)!
        case .week:  selectedDate = cal.date(byAdding: .day,   value: -7, to: selectedDate)!
        case .month: selectedDate = cal.date(byAdding: .month, value: -1, to: selectedDate)!
        }
        Task { await loadIfNeeded(for: selectedDate) }
    }

    // MARK: - Date helpers

    func daysInWeek(containing date: Date) -> [Date] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        let startOfWeek = cal.date(byAdding: .day, value: -(weekday - 1), to: date)!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    func daysInMonth(containing date: Date) -> [Date] {
        let cal  = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: date)
        comps.day = 1
        let start = cal.date(from: comps)!
        let range = cal.range(of: .day, in: .month, for: start)!
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    // MARK: - Conflict detection

    func detectConflicts(_ events: [DotoEvent]) -> [DotoEvent] {
        return events.map { e1 in
            var e = e1
            e.isConflicting = events.contains { e2 in
                e1.id != e2.id &&
                e1.assignedTo.contains(where: { e2.assignedTo.contains($0) }) &&
                e1.startAt < e2.endAt &&
                e1.endAt   > e2.startAt
            }
            return e
        }
    }
}
