import Foundation

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var events: [DotoEvent] = []
    @Published var members: [Profile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate: Date = Date()
    @Published var weekOffset: Int = 0
    @Published var monthOffset: Int = 0
    @Published var monthEvents: [DotoEvent] = []
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
        eventsForDate(selectedDate)
    }

    func eventsForDate(_ date: Date) -> [DotoEvent] {
        let filtered = events.filter { Calendar.current.isDate($0.startAt, inSameDayAs: date) }
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
        } catch is CancellationError {
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

    // MARK: - Monthly

    var currentMonthStart: Date {
        let cal = Calendar.current
        let base = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
        return cal.date(byAdding: .month, value: monthOffset, to: base)!
    }

    var currentMonthLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: currentMonthStart)
    }

    var currentMonthWeeks: [[Date]] {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: currentMonthStart)!
        let allDays = range.compactMap { day -> Date? in
            cal.date(bySetting: .day, value: day, of: currentMonthStart)
        }
        var weeks: [[Date]] = []
        var currentWeek: [Date] = []
        var currentWeekOfYear: Int?
        for day in allDays {
            let woy = cal.component(.weekOfYear, from: day)
            if currentWeekOfYear == nil { currentWeekOfYear = woy }
            if woy != currentWeekOfYear {
                weeks.append(currentWeek)
                currentWeek = []
                currentWeekOfYear = woy
            }
            currentWeek.append(day)
        }
        if !currentWeek.isEmpty { weeks.append(currentWeek) }
        return weeks
    }

    func eventsForDateInMonth(_ date: Date) -> [DotoEvent] {
        let filtered = monthEvents.filter { Calendar.current.isDate($0.startAt, inSameDayAs: date) }
        if let id = selectedMemberId {
            return filtered.filter { $0.assignedTo.contains(id) }
        }
        return filtered
    }

    func loadMonth() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        let cal = Calendar.current
        let monthEnd = cal.date(byAdding: .month, value: 1, to: currentMonthStart)!
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = TimeZone(identifier: "UTC")
        let params = [
            "from": fmt.string(from: currentMonthStart),
            "to":   fmt.string(from: monthEnd)
        ]
        do {
            let fetched: [DotoEvent] = try await APIClient.shared.get("/events", params: params)
            monthEvents = detectConflicts(fetched)
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

    func previousMonth() async { monthOffset -= 1; await loadMonth() }
    func nextMonth()     async { monthOffset += 1; await loadMonth() }

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
