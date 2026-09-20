import Foundation

/// Scope for editing/deleting an occurrence of a recurring series (`?scope=this|future`).
enum TaskScope: String {
    case this, future
}

/// Shared "today + tomorrow" window for materialized recurring occurrences.
/// The backend generates a rolling 28-day window of rows; list surfaces only
/// show occurrences due today or tomorrow, plus pending overdue ones.
enum TaskListWindow {
    static func isVisible(dueDate: Date?, isDone: Bool, isRecurring: Bool) -> Bool {
        guard isRecurring, let due = dueDate else { return true }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dayAfterTomorrow = cal.date(byAdding: .day, value: 2, to: today)!
        if due >= today && due < dayAfterTomorrow { return true }
        return !isDone && due < today
    }

    /// True for a pending recurring occurrence due after today (tomorrow or
    /// the not-yet-started "upcoming" row) — must not be completable.
    static func isFutureOccurrence(dueDate: Date?, isDone: Bool, isRecurring: Bool) -> Bool {
        guard isRecurring, !isDone, let due = dueDate else { return false }
        let tomorrow = Calendar.current.date(
            byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
        return due >= tomorrow
    }

    /// Picks one "upcoming" row per recurring series that would otherwise be
    /// invisible: a brand-new series whose first occurrence starts after
    /// tomorrow and which has no completed occurrence yet. Returns the ids of
    /// the earliest upcoming occurrence of each such series.
    static func upcomingRepresentatives<T: Identifiable>(
        _ rows: [T],
        seriesId: (T) -> String?,
        dueDate: (T) -> Date?,
        isDone: (T) -> Bool
    ) -> Set<String> where T.ID == String {
        var bySeries: [String: [T]] = [:]
        for row in rows {
            if let sid = seriesId(row) { bySeries[sid, default: []].append(row) }
        }
        var result = Set<String>()
        for (_, group) in bySeries {
            let hasVisible = group.contains {
                isVisible(dueDate: dueDate($0), isDone: isDone($0), isRecurring: true)
            }
            let hasCompletion = group.contains { isDone($0) }
            guard !hasVisible && !hasCompletion else { continue }
            if let first = group
                .filter({ dueDate($0) != nil })
                .sorted(by: { dueDate($0)! < dueDate($1)! })
                .first {
                result.insert(first.id)
            }
        }
        return result
    }
}

/// Recurrence rule for a task.
///
/// Mirrors the structured API fields:
///   `repeatRule`  — "none" | "daily" | "weekly" | "custom"
///   `repeatDays`  — weekday numbers, 0 = Sunday … 6 = Saturday (required for "custom";
///                   for "weekly" the backend defaults to dueDate's day-of-week)
///   `repeatUntil` — last date to repeat ("yyyy-MM-dd"), nil = never ends
struct TaskRecurrence: Equatable {
    enum Frequency: String, CaseIterable {
        case none, daily, weekly, custom
    }

    var frequency: Frequency = .none
    /// Calendar weekday numbers (1 = Sunday … 7 = Saturday). Used when frequency == .custom.
    var weekdays: Set<Int> = []
    /// Optional end date; nil = repeats forever.
    var endDate: Date? = nil

    var isRecurring: Bool { frequency != .none }

    // MARK: - Weekday tables (index 0 = Sunday)

    static let weekdayLetters    = ["S", "M", "T", "W", "T", "F", "S"]
    static let weekdayShortNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    // MARK: - API mapping

    /// Build from the raw API fields. `repeatDays` arrive 0-based (0 = Sunday);
    /// internally we use Calendar weekday numbers (1 = Sunday). `fallbackWeekday`
    /// (the task's due-date weekday) is used when a custom rule arrives without days.
    init(repeatRule raw: String?, days: [Int]?, until: Date?, fallbackWeekday: Int?) {
        endDate = until
        switch raw {
        case "daily":
            frequency = .daily
        case "weekly":
            frequency = .weekly
            // `weekly` carries its day in repeatDays too — keep it for prefill.
            if let d = days?.first { weekdays = [d + 1] }
        case "custom":
            let parsed = Set((days ?? []).map { $0 + 1 }).intersection(1...7)
            if parsed.isEmpty, let fb = fallbackWeekday {
                weekdays = [fb]
            } else {
                weekdays = parsed
            }
            frequency = .custom
        default:
            frequency = .none
        }
    }

    init() {}

    /// Value for the `repeatRule` field ("none" is a valid explicit value).
    var apiRepeatRule: String { frequency.rawValue }

    /// Value for the `repeatDays` field (0 = Sunday … 6 = Saturday), only for .custom.
    var apiRepeatDays: [Int]? {
        guard frequency == .custom else { return nil }
        return weekdays.sorted().map { $0 - 1 }
    }

    /// Value for the `repeatUntil` field (nil = never ends / not recurring).
    var apiRepeatUntil: Date? { isRecurring ? endDate : nil }

    // MARK: - Display

    /// Comma-joined short day list, e.g. "Mon, Wed, Fri".
    var dayList: String {
        weekdays.sorted().map { Self.weekdayShortNames[$0 - 1] }.joined(separator: ", ")
    }

    /// Summary for the Add/Edit form row, e.g. "Weekly · Mon, Wed, Fri".
    /// `dueWeekday` labels the plain-weekly option ("Weekly on Thu").
    func summary(dueWeekday: Int? = nil) -> String {
        switch frequency {
        case .none:
            return "None"
        case .daily:
            return "Daily"
        case .weekly:
            if let w = weekdays.sorted().first ?? dueWeekday {
                return "Weekly on \(Self.weekdayShortNames[w - 1])"
            }
            return "Weekly"
        case .custom:
            return weekdays.isEmpty ? "Weekly" : "Weekly · \(dayList)"
        }
    }

    /// Meta-line text for the task list, e.g. "Repeats daily" / "Repeats Mon, Wed, Fri".
    func listSummary(dueWeekday: Int? = nil) -> String {
        switch frequency {
        case .none:
            return ""
        case .daily:
            return "Repeats daily"
        case .weekly:
            if let w = weekdays.sorted().first ?? dueWeekday {
                return "Repeats every \(Self.weekdayShortNames[w - 1])"
            }
            return "Repeats weekly"
        case .custom:
            if weekdays.count == 7 { return "Repeats daily" }
            return weekdays.isEmpty ? "Repeats weekly" : "Repeats \(dayList)"
        }
    }

    /// "until Sep 10, 2026" when an end date is set.
    var endSummary: String? {
        guard let endDate else { return nil }
        return "until \(endDate.shortDate)"
    }
}
