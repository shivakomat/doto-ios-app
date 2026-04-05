import Foundation

// MARK: - Shared

struct DashboardProfile: Decodable {
    let id:            String
    let displayName:   String
    let color:         String
    let role:          String
    let pointsTotal:   Int
    let pointsBalance: Int
    // Child-only fields
    let streak:          Int?
    let streakStatus:    String?
    let streakGraceUsed: Bool?
}

// MARK: - Parent Dashboard

struct ParentDashboardResponse: Decodable {
    let profile:          DashboardProfile
    let family:           DashboardFamily
    let upcomingEvents:   UpcomingEvents
    let overdueCount:     Int
    let recentTasks:      [DashboardTask]
    let familyProgress:   [MemberProgress]
    let shoppingNudge:    ShoppingNudge?
    let pendingApprovals: [PendingApproval]
}

struct DashboardFamily: Decodable {
    let id:      String
    let name:    String
    let members: [FamilyMemberSummary]
}

struct FamilyMemberSummary: Decodable, Identifiable {
    let id:           String
    let displayName:  String
    let role:         String
    let color:        String
    let pointsTotal:  Int
    let streak:       Int
    let streakStatus: String
}

struct UpcomingEvents: Decodable {
    let days: [DashboardDay]
}

struct DashboardDay: Decodable, Identifiable {
    var id: String { date }
    let date:         String
    let dayLabel:     String
    let dayNumber:    String
    let isToday:      Bool
    let hasConflict:  Bool
    let memberColors: [String]
    let events:       [DashboardEvent]
}

struct DashboardEvent: Decodable, Identifiable {
    let id:            String
    let title:         String
    let startAt:       Date
    let endAt:         Date
    let location:      String?
    let assignedTo:    [String]
    let isConflicting: Bool

    var durationMinutes: Int {
        Int(endAt.timeIntervalSince(startAt) / 60)
    }
}

struct DashboardTask: Decodable, Identifiable {
    let id:            String
    let title:         String
    let assignedTo:    String?
    let assigneeName:  String?
    let assigneeColor: String?
    let priority:      String
    let points:        Int
    let dueAt:         Date
    var status:        String
    let isOverdue:     Bool

    var isDone: Bool { status == "done" }
}

struct MemberProgress: Decodable, Identifiable {
    var id: String { memberId }
    let memberId:       String
    let displayName:    String
    let color:          String
    let tasksCompleted: Int
    let tasksTotal:     Int

    var progressFraction: Double {
        guard tasksTotal > 0 else { return 0 }
        return Double(tasksCompleted) / Double(tasksTotal)
    }
}

struct ShoppingNudge: Decodable {
    let listId:         String
    let listName:       String
    let uncheckedCount: Int
    let lastUpdatedAt:  Date
}

struct PendingApproval: Decodable, Identifiable {
    let id:            String
    let memberId:      String
    let memberName:    String
    let memberColor:   String
    let title:         String
    let emoji:         String?
    let pointsCost:    Int
    let memberBalance: Int
    let requestedAt:   Date
}

// MARK: - Child Dashboard

struct ChildDashboardResponse: Decodable {
    let profile:        DashboardProfile
    let stats:          ChildStats
    let activeGoal:     ActiveGoal?
    let todaysTasks:    [ChildTask]
    let upcomingEvents: [DashboardEvent]
    let familyMembers:  [FamilyMemberRow]
}

struct ChildStats: Decodable {
    let weeklyPoints: Int
    let weeklyRank:   Int
    let totalMembers: Int
}

struct ActiveGoal: Decodable {
    let id:          String
    let title:       String
    let emoji:       String?
    let pointsCost:  Int
    let status:      String
    let progressPct: Int
}

struct ChildTask: Decodable, Identifiable {
    let id:        String
    let title:     String
    let points:    Int
    let status:    String
    let dueAt:     Date
    let isOverdue: Bool

    var isDone: Bool { status == "done" }
}

struct FamilyMemberRow: Decodable, Identifiable {
    let id:           String
    let displayName:  String
    let color:        String
    let role:         String
    let weeklyPoints: Int
    let streak:       Int
    let streakStatus: String
    let isSelf:       Bool

    var streakDisplay: String {
        switch streakStatus {
        case "active": return "🔥 \(streak)"
        case "grace":  return "🔸 \(streak)"
        default:       return "\(weeklyPoints) pts"
        }
    }
}

// MARK: - Helpers

extension DashboardEvent {
    func asDotoEvent() -> DotoEvent {
        DotoEvent(id: id, familyId: nil, title: title, description: nil,
                  startAt: startAt, endAt: endAt, location: location, color: nil,
                  repeat_: nil, assignedTo: assignedTo,
                  createdBy: nil, createdAt: nil, updatedAt: nil, isConflicting: isConflicting)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
