import Foundation

extension Date {
    static let shortTimeFormatter: DateFormatter = {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none; return f
    }()
    static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()

    var shortTime: String { Date.shortTimeFormatter.string(from: self) }
    var shortDate: String { Date.shortDateFormatter.string(from: self) }

    var relativeDue: String {
        if Calendar.current.isDateInToday(self)     { return "Today" }
        if Calendar.current.isDateInTomorrow(self)  { return "Tomorrow" }
        if Calendar.current.isDateInYesterday(self) { return "Yesterday" }
        return shortDate
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: self)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var weekBounds: (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
        let end   = cal.date(byAdding: .day, value: 7, to: start)!
        return (start, end)
    }

    var isPast: Bool { self < Date() }

    var fullDateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: self)
    }

    var durationString: String {
        ""
    }

    func duration(to end: Date) -> String {
        let mins = Int(end.timeIntervalSince(self) / 60)
        if mins < 60 { return "\(mins) min" }
        let h = mins / 60; let m = mins % 60
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }
}
