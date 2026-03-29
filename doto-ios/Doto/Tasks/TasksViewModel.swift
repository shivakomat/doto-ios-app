import Foundation

@MainActor
class TasksViewModel: ObservableObject {
    @Published var tasks: [DotoTask] = []
    @Published var members: [Profile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            async let t: [DotoTask] = APIClient.shared.get("/tasks")
            async let f: Family     = APIClient.shared.get("/families/mine")
            let (fetchedTasks, fetchedFamily) = try await (t, f)
            tasks   = fetchedTasks
            members = fetchedFamily.members
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeTask(_ task: DotoTask) async {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
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

    func deleteTask(_ task: DotoTask) async {
        do {
            try await APIClient.shared.delete("/tasks/\(task.id)")
            tasks.removeAll { $0.id == task.id }
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func tasksForMember(_ id: String) -> [DotoTask] {
        tasks.filter { $0.assignedTo == id }
    }
}
