import Foundation

@MainActor
class DashboardViewModel: ObservableObject {

    // Parent data
    @Published var parentData: ParentDashboardResponse?

    // Child data
    @Published var childData: ChildDashboardResponse?

    // Shared state
    @Published var isLoading        = false
    @Published var errorMessage:    String?
    @Published var selectedDayIndex = 0

    // Child task completion (optimistic)
    @Published var completingTaskIds: Set<String> = []

    func load(role: String) async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            if role == "parent" {
                let data: ParentDashboardResponse = try await APIClient.shared.get("/dashboard")
                NSLog("[DASHBOARD] Loaded parent data - Events days: \(data.upcomingEvents.days.count)")
                for (idx, day) in data.upcomingEvents.days.enumerated() {
                    NSLog("[DASHBOARD]   Day \(idx): \(day.date) - \(day.events.count) events")
                }
                parentData = data
            } else {
                let data: ChildDashboardResponse = try await APIClient.shared.get("/dashboard")
                NSLog("[DASHBOARD] Loaded child data - Events: \(data.upcomingEvents.count)")
                childData = data
            }
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

    // Child completes a task from dashboard — optimistic UI
    func completeTask(_ task: ChildTask) async {
        guard !completingTaskIds.contains(task.id) else { return }
        completingTaskIds.insert(task.id)

        // Optimistic: update local state immediately by creating new array
        if let data = childData,
           let idx = data.todaysTasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTasks = data.todaysTasks
            updatedTasks[idx] = ChildTask(
                id: task.id, title: task.title, points: task.points,
                status: "done", dueAt: task.dueAt, isOverdue: false
            )
            childData = ChildDashboardResponse(
                profile: data.profile,
                stats: data.stats,
                activeGoal: data.activeGoal,
                todaysTasks: updatedTasks,
                upcomingEvents: data.upcomingEvents,
                familyMembers: data.familyMembers
            )
        }

        do {
            let _: DotoTask = try await APIClient.shared.patch(
                "/tasks/\(task.id)/complete"
            )
        } catch {
            // Revert on failure
            await load(role: "child")
        }

        completingTaskIds.remove(task.id)
    }

    var selectedDay: DashboardDay? {
        parentData?.upcomingEvents.days[safe: selectedDayIndex]
    }
}
