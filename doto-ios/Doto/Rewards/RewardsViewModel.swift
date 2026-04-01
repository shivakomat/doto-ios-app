import Foundation

@MainActor
class RewardsViewModel: ObservableObject {
    @Published var leaderboard: Leaderboard?
    @Published var rewards: [Reward] = []
    @Published var pendingApprovals: [Reward] = []
    @Published var catalog: [RewardCatalogItem] = []
    @Published var familyGoal: FamilyGoal?
    @Published var pendingMilestone: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var showBonusSheet = false
    @Published var bonusTargetMemberId: String?

    var activeGoals: [Reward] {
        rewards.filter { $0.status == "active" || $0.status == "approved" }
    }

    // MARK: - Load

    func loadAll() async {
        isLoading = true; defer { isLoading = false }
        async let lb: () = loadLeaderboard()
        async let rw: () = loadRewards()
        async let cat: () = loadCatalog()
        async let fg: () = loadFamilyGoal()
        await lb; await rw; await cat; await fg
    }

    func loadLeaderboard() async {
        do {
            leaderboard = try await APIClient.shared.get("/rewards/leaderboard")
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadRewards() async {
        do {
            let all: [Reward] = try await APIClient.shared.get("/rewards")
            rewards = all.filter { $0.status != "pending_approval" }
            pendingApprovals = all.filter { $0.status == "pending_approval" }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCatalog() async {
        do {
            catalog = try await APIClient.shared.get("/rewards/catalog")
        } catch { /* catalog may not exist yet — non-fatal */ }
    }

    func loadFamilyGoal() async {
        do {
            familyGoal = try await APIClient.shared.get("/family-goals/active")
        } catch { /* no active goal — non-fatal */ }
    }

    // MARK: - Reward Actions

    func requestReward(_ reward: Reward) async {
        do {
            let updated: Reward = try await APIClient.shared.patch("/rewards/\(reward.id)/request")
            updateReward(updated)
        } catch APIError.conflict(let msg) {
            errorMessage = msg
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func approveReward(_ reward: Reward) async {
        do {
            let updated: Reward = try await APIClient.shared.patch("/rewards/\(reward.id)/approve")
            updateReward(updated)
            pendingApprovals.removeAll { $0.id == reward.id }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func declineReward(_ reward: Reward) async {
        do {
            let updated: Reward = try await APIClient.shared.patch("/rewards/\(reward.id)/decline")
            updateReward(updated)
            pendingApprovals.removeAll { $0.id == reward.id }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func redeemReward(_ reward: Reward) async {
        struct RedeemResponse: Decodable { let reward: Reward; let member: MemberPointsUpdate }
        do {
            let res: RedeemResponse = try await APIClient.shared.patch("/rewards/\(reward.id)/redeem")
            updateReward(res.reward)
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteReward(_ reward: Reward) async {
        do {
            try await APIClient.shared.delete("/rewards/\(reward.id)")
            rewards.removeAll { $0.id == reward.id }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createReward(memberId: String, title: String, emoji: String?,
                      pointsCost: Int, catalogItemId: String?) async {
        struct CreateRewardRequest: Encodable {
            let memberId: String; let title: String; let emoji: String?
            let pointsCost: Int; let catalogItemId: String?
        }
        do {
            let r: Reward = try await APIClient.shared.post("/rewards",
                body: CreateRewardRequest(memberId: memberId, title: title,
                                          emoji: emoji, pointsCost: pointsCost,
                                          catalogItemId: catalogItemId))
            rewards.append(r)
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Bonus Points

    func giveBonusPoints(toMemberId: String, amount: Int, note: String?) async {
        do {
            let res: BonusPointsResponse = try await APIClient.shared.post(
                "/members/\(toMemberId)/bonus-points",
                body: BonusPointsRequest(amount: amount, note: note)
            )
            if let milestone = res.newMilestone {
                pendingMilestone = milestone
            }
            showBonusSheet = false
            await loadLeaderboard()
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func updateReward(_ updated: Reward) {
        if let i = rewards.firstIndex(where: { $0.id == updated.id }) {
            rewards[i] = updated
        }
    }
}
