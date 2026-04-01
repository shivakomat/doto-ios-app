import SwiftUI

struct PointsHistoryView: View {
    let memberId: String
    let displayName: String

    @StateObject private var vm = PointsHistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if vm.isLoading && vm.groupedEntries.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.groupedEntries) { group in
                            Section(header: Text(group.dateLabel)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.textMuted)) {
                                ForEach(group.entries) { entry in
                                    PointsHistoryRow(entry: entry)
                                }
                            }
                        }

                        if vm.hasMore {
                            Button {
                                Task { await vm.loadMore() }
                            } label: {
                                HStack {
                                    if vm.isLoadingMore {
                                        ProgressView()
                                    } else {
                                        Text("Load more")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("\(displayName)'s history")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Text("\(vm.history?.pointsTotal ?? 0) pts")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.memberBlue)
                }
            }
            .task { await vm.load(memberId: memberId) }
        }
    }
}

struct PointsHistoryRow: View {
    let entry: PointsHistoryEntry

    var body: some View {
        if entry.eventType == "milestone" {
            MilestoneHistoryCard(note: entry.note ?? "Milestone reached!")
        } else {
            HStack(spacing: 12) {
                Image(systemName: entry.icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: entry.iconColor))
                    .frame(width: 24, height: 24)
                    .background(Color(hex: entry.iconColor).opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.note ?? entry.eventType.capitalized)
                        .font(.system(size: 13))
                        .foregroundColor(.textPrimary)
                    if entry.eventType == "bonus" {
                        Text("Bonus from parent")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                }

                Spacer()

                Text(entry.isEarning ? "+\(entry.amount)" : "\(entry.amount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(entry.isEarning
                        ? Color(hex: "#1D9E75")
                        : Color(hex: "#E24B4A"))
            }
            .padding(.vertical, 4)
        }
    }
}

struct MilestoneHistoryCard: View {
    let note: String

    var body: some View {
        HStack(spacing: 10) {
            Text("🏅").font(.system(size: 20))
            Text(note)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.memberBlue)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#EFF6FF"))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.memberBlue.opacity(0.3), lineWidth: 1))
        .cornerRadius(8)
    }
}
