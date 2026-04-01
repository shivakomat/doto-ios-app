import Foundation

@MainActor
class PointsHistoryViewModel: ObservableObject {
    @Published var history: PointsHistoryResponse?
    @Published var groupedEntries: [DayGroup] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = false
    @Published var errorMessage: String?

    private var memberId = ""
    private var nextBefore: Date?

    struct DayGroup: Identifiable {
        var id: String { date }
        let date: String
        let dateLabel: String
        let entries: [PointsHistoryEntry]
    }

    func load(memberId: String) async {
        self.memberId = memberId
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let res: PointsHistoryResponse = try await APIClient.shared.get(
                "/members/\(memberId)/points-history"
            )
            history = res
            hasMore = res.hasMore
            nextBefore = res.nextBefore
            groupedEntries = groupByDay(res.entries)
        } catch APIError.unauthorized {
            NotificationCenter.default.post(name: .dotoUnauthorized, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard hasMore, let before = nextBefore else { return }
        isLoadingMore = true; defer { isLoadingMore = false }
        do {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let beforeStr = formatter.string(from: before)
            let res: PointsHistoryResponse = try await APIClient.shared.get(
                "/members/\(memberId)/points-history",
                params: ["before": beforeStr]
            )
            hasMore = res.hasMore
            nextBefore = res.nextBefore
            let newGroups = groupByDay(res.entries)
            mergeGroups(newGroups)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func groupByDay(_ entries: [PointsHistoryEntry]) -> [DayGroup] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            cal.startOfDay(for: entry.createdAt)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { date, items in
                DayGroup(
                    date: date.ISO8601Format(),
                    dateLabel: dayLabel(date),
                    entries: items.sorted { $0.createdAt > $1.createdAt }
                )
            }
    }

    private func mergeGroups(_ newGroups: [DayGroup]) {
        for group in newGroups {
            if let idx = groupedEntries.firstIndex(where: { $0.date == group.date }) {
                let merged = groupedEntries[idx].entries + group.entries
                groupedEntries[idx] = DayGroup(
                    date: group.date,
                    dateLabel: group.dateLabel,
                    entries: merged.sorted { $0.createdAt > $1.createdAt }
                )
            } else {
                groupedEntries.append(group)
            }
        }
        groupedEntries.sort { $0.date > $1.date }
    }

    private func dayLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }
}
