import Foundation
import SwiftUI

struct DotoTask: Codable, Identifiable {
    let id: String
    let familyId: String?
    var title: String
    var notes: String?
    var assignedTo: String?
    var priority: String?
    var status: String?
    /// Server-provided category; nil on old payloads — see `type`.
    var taskType: TaskType?
    /// Server-provided SF Symbol name; nil on old payloads — see `resolvedIcon`.
    var icon: String?
    /// Routine-only daily bucket: "morning" | "afternoon" | "evening".
    var timeOfDay: String?
    var points: Int
    /// Due date ("yyyy-MM-dd") — decoded as local start-of-day.
    var dueDate: Date?
    var repeatRule: String?
    /// Weekday numbers, 0 = Sunday … 6 = Saturday (custom rules).
    var repeatDays: [Int]?
    /// Last date to repeat ("yyyy-MM-dd"); nil = never.
    var repeatUntil: Date?
    var completedAt: Date?
    var rewardGoalId: String?
    /// Groups all generated occurrences of a recurring series.
    var seriesId: String?
    /// True only for the first occurrence of a series.
    var isSeriesParent: Bool?
    /// Server-provided flag, true when the task belongs to a series.
    var isRecurringFlag: Bool?
    let createdBy: String?
    let createdAt: Date?
    let updatedAt: Date?

    /// True when the task belongs to a recurring series.
    var isRecurring: Bool {
        isRecurringFlag == true || seriesId != nil || (repeatRule != nil && repeatRule != "none")
    }

    var isOverdue: Bool {
        guard let due = dueDate else { return false }
        return status != "done" && due < Calendar.current.startOfDay(for: Date())
    }
    var isDueToday: Bool {
        guard let due = dueDate else { return false }
        return status != "done" && Calendar.current.isDateInToday(due)
    }
    /// Effective category — tasks created before V1.1 decode as `.chore`.
    var type: TaskType { taskType ?? .chore }

    /// SF Symbol name guaranteed to render on this device.
    var resolvedIcon: String {
        TaskIconCatalog.resolve(icon ?? TaskIconCatalog.defaultSymbol)
    }

    /// Category color of the chosen icon; falls back to the type color.
    var iconColor: Color {
        TaskIconCatalog.color(for: icon ?? TaskIconCatalog.defaultSymbol) ?? type.color
    }

    /// Display label for the routine's daily bucket, e.g. "Morning".
    var timeOfDayLabel: String? {
        timeOfDay?.capitalized
    }

    /// SF Symbol for the routine's daily bucket.
    var timeOfDayIcon: String {
        switch timeOfDay {
        case "morning":   return "sunrise.fill"
        case "afternoon": return "sun.max.fill"
        case "evening":   return "moon.fill"
        default:          return "clock"
        }
    }

    var isDone: Bool { status == "done" }

    /// Pending recurring occurrence due tomorrow or later — not completable yet.
    var isFutureOccurrence: Bool {
        TaskListWindow.isFutureOccurrence(dueDate: dueDate, isDone: isDone, isRecurring: isRecurring)
    }

    var dueWeekday: Int {
        Calendar.current.component(.weekday, from: dueDate ?? Date())
    }

    var recurrence: TaskRecurrence {
        TaskRecurrence(repeatRule: repeatRule, days: repeatDays, until: repeatUntil,
                       fallbackWeekday: dueDate == nil ? nil : dueWeekday)
    }

    /// "Completed at 4:12 PM"
    var completedTimeLabel: String? {
        completedAt.map { "Completed at \($0.shortTime)" }
    }

    private enum CodingKeys: String, CodingKey {
        case id, familyId, title, notes, assignedTo, priority, status, taskType, points, icon
        case timeOfDay
        case dueDate, repeatRule, repeatDays, repeatUntil, completedAt, rewardGoalId
        case seriesId, isSeriesParent, createdBy, createdAt, updatedAt
        case isRecurringFlag = "isRecurring"
    }
}
