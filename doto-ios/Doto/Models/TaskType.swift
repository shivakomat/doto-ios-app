import SwiftUI

/// Task category. All types earn points; the API is authoritative.
enum TaskType: String, CaseIterable {
    case chore, routine, homework, errand

    /// Unknown or removed API values (e.g. legacy "other") decode as chore.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TaskType(rawValue: raw) ?? .chore
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var label: String {
        switch self {
        case .chore:    return "Chore"
        case .homework: return "Homework"
        case .errand:   return "Errand"
        case .routine:  return "Routine"
        }
    }

    var pluralLabel: String {
        switch self {
        case .chore:    return "chores"
        case .homework: return "homework"
        case .errand:   return "errands"
        case .routine:  return "routines"
        }
    }

    var icon: String {
        switch self {
        case .chore:    return "house.fill"
        case .homework: return "book.fill"
        case .errand:   return "bag.fill"
        case .routine:  return "arrow.triangle.2.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .chore:    return Color(hex: "#F59E0B")
        case .homework: return Color(hex: "#3A7BD5")
        case .errand:   return Color(hex: "#8B5CF6")
        case .routine:  return Color(hex: "#1D9E75")
        }
    }

    var earnsPoints: Bool { true }
}

extension TaskType: Codable {}
