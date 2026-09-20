import Foundation

@MainActor
class TasksViewModel: ObservableObject {
    @Published var tasks: [DotoTask] = []
    @Published var members: [Profile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var hasCompletedTasks: Bool {
        tasks.contains { $0.isDone }
    }

    func load() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            // The backend materializes a rolling 28-day window of occurrences;
            // GET /tasks returns every generated row.
            async let t: [DotoTask] = APIClient.shared.get("/tasks")
            async let f: Family     = APIClient.shared.get("/families/mine")
            let (fetchedTasks, fetchedFamily) = try await (t, f)
            tasks   = fetchedTasks
            members = fetchedFamily.members
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeTask(_ task: DotoTask) async {
        // Recurring occurrences due tomorrow or later cannot be completed yet.
        guard !task.isFutureOccurrence,
              let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].status = "done"
        tasks[idx].completedAt = Date()
        do {
            let updated: DotoTask = try await APIClient.shared.patch("/tasks/\(task.id)/complete")
            tasks[idx] = updated
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            tasks[idx].status = task.status
            tasks[idx].completedAt = task.completedAt
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ task: DotoTask, scope: TaskScope = .this) async {
        do {
            let path = task.isRecurring
                ? "/tasks/\(task.id)?scope=\(scope.rawValue)"
                : "/tasks/\(task.id)"
            try await APIClient.shared.delete(path)
            if scope == .future, let sid = task.seriesId {
                // Drop this and all later occurrences of the series locally.
                let cutoff = task.dueDate ?? .distantPast
                tasks.removeAll { $0.seriesId == sid && ($0.dueDate ?? .distantPast) >= cutoff }
            } else {
                tasks.removeAll { $0.id == task.id }
            }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func tasksForMember(_ id: String) -> [DotoTask] {
        let mine = tasks.filter { $0.assignedTo == id }
        let upcoming = TaskListWindow.upcomingRepresentatives(
            mine, seriesId: { $0.seriesId }, dueDate: { $0.dueDate }, isDone: { $0.isDone })
        return mine.filter { isVisibleInWindow($0) || upcoming.contains($0.id) }
    }

    /// The backend materializes a 28-day window of occurrences — the list only
    /// shows recurring rows due today or tomorrow (plus pending overdue ones).
    private func isVisibleInWindow(_ task: DotoTask) -> Bool {
        TaskListWindow.isVisible(dueDate: task.dueDate, isDone: task.isDone, isRecurring: task.isRecurring)
    }

    func clearCompleted(memberId: String? = nil) async {
        do {
            var path = "/tasks/completed"
            if let id = memberId {
                path += "?memberId=\(id)"
            }
            struct BulkDeleteResponse: Decodable { let deletedCount: Int }
            let res: BulkDeleteResponse = try await APIClient.shared.delete(path)
            // Remove completed tasks from local array
            if let id = memberId {
                tasks.removeAll { $0.isDone && $0.assignedTo == id }
            } else {
                tasks.removeAll { $0.isDone }
            }
            NSLog("[DOTO] Cleared %d completed tasks", res.deletedCount)
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
