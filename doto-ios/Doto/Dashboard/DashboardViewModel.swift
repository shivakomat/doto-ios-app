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

    // Parent task completion (optimistic)
    @Published var completingParentTaskIds: Set<String> = []

    /// Ids of recurring rows due tomorrow or later — not completable.
    @Published var lockedTaskIds: Set<String> = []

    func load(role: String) async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            // /dashboard task objects may not carry recurrence fields, so we
            // cross-reference GET /tasks to detect recurring occurrence rows
            // and to map each row to its seriesId.
            let recurringInfoTask = Task { () -> (ids: Set<String>, series: [String: String]) in
                let all: [DotoTask] = (try? await APIClient.shared.get("/tasks")) ?? []
                let ids = Set(all.filter { $0.isRecurring }.map(\.id))
                var series: [String: String] = [:]
                for t in all { if let sid = t.seriesId { series[t.id] = sid } }
                return (ids, series)
            }

            if role == "parent" {
                let data: ParentDashboardResponse = try await APIClient.shared.get("/dashboard")
                let recInfo = await recurringInfoTask.value
                NSLog("[DASHBOARD] Loaded parent data - Events days: \(data.upcomingEvents.days.count)")
                for (idx, day) in data.upcomingEvents.days.enumerated() {
                    NSLog("[DASHBOARD]   Day \(idx): \(day.date) - \(day.events.count) events")
                }
                // Window recurring occurrences to today + tomorrow
                let upcomingIds = TaskListWindow.upcomingRepresentatives(
                    data.recentTasks,
                    seriesId: { $0.seriesId ?? recInfo.series[$0.id] },
                    dueDate: { $0.dueDate },
                    isDone: { $0.isDone })
                let visibleTasks = data.recentTasks.filter {
                    let rec = $0.isRecurringTask || recInfo.ids.contains($0.id)
                    return TaskListWindow.isVisible(dueDate: $0.dueDate, isDone: $0.isDone, isRecurring: rec)
                        || upcomingIds.contains($0.id)
                }
                // Recurring rows due tomorrow or later are locked (not completable).
                lockedTaskIds = Set(visibleTasks.filter {
                    TaskListWindow.isFutureOccurrence(
                        dueDate: $0.dueDate, isDone: $0.isDone,
                        isRecurring: $0.isRecurringTask || recInfo.ids.contains($0.id))
                }.map(\.id))
                parentData = ParentDashboardResponse(
                    profile: data.profile,
                    family: data.family,
                    upcomingEvents: data.upcomingEvents,
                    overdueCount: data.overdueCount,
                    recentTasks: visibleTasks,
                    familyProgress: data.familyProgress,
                    shoppingNudge: data.shoppingNudge,
                    pendingApprovals: data.pendingApprovals
                )
            } else {
                let data: ChildDashboardResponse = try await APIClient.shared.get("/dashboard")
                let recInfo = await recurringInfoTask.value
                NSLog("[DASHBOARD] Loaded child data - Events: \(data.upcomingEvents.count)")
                let upcomingIds = TaskListWindow.upcomingRepresentatives(
                    data.todaysTasks,
                    seriesId: { recInfo.series[$0.id] },
                    dueDate: { $0.dueDate },
                    isDone: { $0.isDone })
                let visibleTasks = data.todaysTasks.filter {
                    let rec = $0.isRecurring == true || recInfo.ids.contains($0.id)
                    return TaskListWindow.isVisible(dueDate: $0.dueDate, isDone: $0.isDone, isRecurring: rec)
                        || upcomingIds.contains($0.id)
                }
                lockedTaskIds = Set(visibleTasks.filter {
                    TaskListWindow.isFutureOccurrence(
                        dueDate: $0.dueDate, isDone: $0.isDone,
                        isRecurring: $0.isRecurring == true || recInfo.ids.contains($0.id))
                }.map(\.id))
                childData = ChildDashboardResponse(
                    profile: data.profile,
                    stats: data.stats,
                    activeGoal: data.activeGoal,
                    todaysTasks: visibleTasks,
                    upcomingEvents: data.upcomingEvents,
                    familyMembers: data.familyMembers
                )
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
                id: task.id, title: task.title, taskType: task.taskType,
                icon: task.icon, timeOfDay: task.timeOfDay,
                points: task.points,
                status: "done", dueDate: task.dueDate, isOverdue: false,
                isRecurring: task.isRecurring
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

    // Parent completes a task from dashboard — optimistic UI
    func completeParentTask(_ task: DashboardTask) async {
        guard !completingParentTaskIds.contains(task.id) else { return }
        completingParentTaskIds.insert(task.id)

        // Optimistic: mark as done locally
        if let data = parentData,
           let idx = data.recentTasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTasks = data.recentTasks
            updatedTasks[idx].status = "done"
            parentData = ParentDashboardResponse(
                profile: data.profile,
                family: data.family,
                upcomingEvents: data.upcomingEvents,
                overdueCount: data.overdueCount,
                recentTasks: updatedTasks,
                familyProgress: data.familyProgress,
                shoppingNudge: data.shoppingNudge,
                pendingApprovals: data.pendingApprovals
            )
        }

        do {
            let _: DotoTask = try await APIClient.shared.patch(
                "/tasks/\(task.id)/complete"
            )
        } catch {
            // Revert on failure
            await load(role: "parent")
        }

        completingParentTaskIds.remove(task.id)
    }

    var selectedDay: DashboardDay? {
        parentData?.upcomingEvents.days[safe: selectedDayIndex]
    }
}
