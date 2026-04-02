import Foundation

struct DashboardResponse: Decodable {
    let family: FamilySnapshot
    let todaysEvents: [EventSnapshot]
    let pendingTasks: [TaskSnapshot]
    let pendingApprovals: [ApprovalSnapshot]

    private enum CodingKeys: String, CodingKey {
        case family, todaysEvents, upcomingEvents, pendingTasks, pendingApprovals
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        family           = try c.decode(FamilySnapshot.self, forKey: .family)
        todaysEvents     = (try? c.decode([EventSnapshot].self, forKey: .todaysEvents))
                        ?? (try? c.decode([EventSnapshot].self, forKey: .upcomingEvents))
                        ?? []
        pendingTasks     = (try? c.decode([TaskSnapshot].self,    forKey: .pendingTasks))     ?? []
        pendingApprovals = (try? c.decode([ApprovalSnapshot].self, forKey: .pendingApprovals)) ?? []
    }
}

struct FamilySnapshot: Decodable {
    let id: String
    let name: String
    let members: [MemberSnapshot]
}

struct MemberSnapshot: Decodable, Identifiable {
    let id: String
    let username: String?
    let displayName: String
    let role: String
    let color: String
    let pointsTotal: Int
    let pointsBalance: Int
    let streak: Int?

    private enum CodingKeys: String, CodingKey {
        case id, username, displayName, role, color
        case pointsTotal, pointsBalance, points
        case streak
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(String.self, forKey: .id)
        username     = try c.decodeIfPresent(String.self, forKey: .username)
        displayName  = try c.decode(String.self, forKey: .displayName)
        role         = try c.decode(String.self, forKey: .role)
        color        = try c.decode(String.self, forKey: .color)
        let fallback = try c.decodeIfPresent(Int.self, forKey: .points) ?? 0
        pointsTotal  = try c.decodeIfPresent(Int.self, forKey: .pointsTotal) ?? fallback
        pointsBalance = try c.decodeIfPresent(Int.self, forKey: .pointsBalance) ?? fallback
        streak       = try c.decodeIfPresent(Int.self, forKey: .streak)
    }
}

struct EventSnapshot: Decodable, Identifiable {
    let id: String
    let title: String
    let startAt: Date
    let endAt: Date
    let assignedTo: [String]
    let color: String?
}

struct TaskSnapshot: Decodable, Identifiable {
    let id: String
    let title: String
    let assignedTo: String?
    let priority: String
    let points: Int
    let dueAt: Date?
}

struct ApprovalSnapshot: Decodable, Identifiable {
    let id: String
    let memberId: String
    let title: String
    let pointsCost: Int
    let status: String
}

extension EventSnapshot {
    func asDotoEvent() -> DotoEvent {
        DotoEvent(id: id, familyId: nil, title: title, description: nil,
                  startAt: startAt, endAt: endAt, location: nil, color: color,
                  repeat_: nil, assignedTo: assignedTo,
                  createdBy: nil, createdAt: nil, updatedAt: nil, isConflicting: false)
    }
}

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var todaysEvents: [EventSnapshot] = []
    @Published var pendingTasks: [TaskSnapshot] = []
    @Published var members: [MemberSnapshot] = []
    @Published var pendingApprovals: [ApprovalSnapshot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedMemberId: String? = nil

    var pendingTasksCount: Int { pendingTasks.count }

    var filteredEvents: [EventSnapshot] {
        guard let id = selectedMemberId else { return todaysEvents }
        return todaysEvents.filter { $0.assignedTo.contains(id) }
    }

    func load() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let res: DashboardResponse = try await APIClient.shared.get("/dashboard")
            todaysEvents     = res.todaysEvents
            pendingTasks     = res.pendingTasks
            members          = res.family.members
            pendingApprovals = res.pendingApprovals
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch is CancellationError {
            return
        } catch let urlErr as URLError where urlErr.code == .cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleMemberFilter(_ id: String) {
        selectedMemberId = (selectedMemberId == id) ? nil : id
    }
}
