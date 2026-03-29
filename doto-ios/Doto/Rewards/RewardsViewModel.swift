import Foundation

@MainActor
class RewardsViewModel: ObservableObject {
    @Published var rewards: [Reward] = []
    @Published var tasks: [DotoTask] = []
    @Published var members: [Profile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var activeGoals: [Reward] {
        rewards.filter { $0.status == "active" || $0.status == "pending_approval" }
    }

    func weeklyPoints(for memberId: String) -> Int {
        let (weekStart, _) = Date().weekBounds
        return tasks
            .filter { $0.assignedTo == memberId && $0.isDone }
            .filter { ($0.completedAt ?? .distantPast) >= weekStart }
            .reduce(0) { $0 + $1.points }
    }

    func leaderboard() -> [(profile: Profile, points: Int)] {
        members
            .map { m in (profile: m, points: weeklyPoints(for: m.id)) }
            .sorted { $0.points > $1.points }
    }

    func load() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            async let r: [Reward]  = APIClient.shared.get("/rewards")
            async let t: [DotoTask] = APIClient.shared.get("/tasks")
            async let f: Family     = APIClient.shared.get("/families/mine")
            let (fetchedRewards, fetchedTasks, fetchedFamily) = try await (r, t, f)
            rewards = fetchedRewards
            tasks   = fetchedTasks
            members = fetchedFamily.members
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestReward(_ reward: Reward) async {
        do {
            let updated: Reward = try await APIClient.shared.patch("/rewards/\(reward.id)/request")
            if let idx = rewards.firstIndex(where: { $0.id == reward.id }) {
                rewards[idx] = updated
            }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func approveReward(_ reward: Reward) async {
        do {
            let updated: Reward = try await APIClient.shared.patch("/rewards/\(reward.id)/approve")
            if let idx = rewards.firstIndex(where: { $0.id == reward.id }) {
                rewards[idx] = updated
            }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func declineReward(_ reward: Reward) async {
        do {
            let updated: Reward = try await APIClient.shared.patch("/rewards/\(reward.id)/decline")
            if let idx = rewards.firstIndex(where: { $0.id == reward.id }) {
                rewards[idx] = updated
            }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createReward(title: String, pointsCost: Int, memberId: String) async {
        struct CreateRewardRequest: Encodable { let title: String; let pointsCost: Int; let memberId: String }
        do {
            let reward: Reward = try await APIClient.shared.post(
                "/rewards",
                body: CreateRewardRequest(title: title, pointsCost: pointsCost, memberId: memberId)
            )
            rewards.append(reward)
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
