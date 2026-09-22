import SwiftUI

struct RewardCatalogView: View {
    @StateObject private var vm = RewardCatalogViewModel()
    @Environment(\.dismiss) private var dismiss

    private let suggestions: [(category: RewardCategory, title: String, cost: Int)] = [
        (.movieEntertainment, "Movie night",        100),
        (.treatsFood,         "Choose dinner",       50),
        (.screenTime,         "Extra screen time",   75),
        (.lateBedtime,        "Stay up late (Fri)",  80),
        (.outing,             "Day out",            300),
        (.sleepoverFriends,   "Friend sleepover",   150),
        (.skipChore,          "Day off chores",      60),
        (.chooseActivity,     "New book",            80),
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if vm.items.isEmpty && !vm.isLoading {
                    VStack(spacing: 12) {
                        Spacer()
                        Text("No rewards in the catalog yet.\nAdd some for your children to choose from.")
                            .font(.system(size: 14))
                            .foregroundColor(.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(32)
                        suggestionsGrid
                        Spacer()
                    }
                } else {
                    List {
                        Section {
                            ForEach(vm.items) { item in
                                catalogRow(item)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            Task { await vm.deleteItem(item) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            vm.editingItem = item
                                            vm.showAddSheet = true
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(Color.memberBlue)
                                    }
                            }
                        }

                        Section(header: Text("Quick-add suggestions")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.textMuted)) {
                            suggestionsGrid
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Reward catalog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("+ Add") { vm.editingItem = nil; vm.showAddSheet = true }
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .task { await vm.load() }
            .sheet(isPresented: $vm.showAddSheet, onDismiss: { vm.editingItem = nil }) {
                RewardCatalogFormView(editingItem: vm.editingItem) { category, title, cost, description in
                    Task {
                        if let editing = vm.editingItem {
                            await vm.updateItem(id: editing.id, category: category, title: title, cost: cost, description: description)
                        } else {
                            await vm.addItem(category: category, title: title, cost: cost, description: description)
                        }
                        vm.showAddSheet = false
                    }
                }
            }
            .alert("Something went wrong",
                   isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private func catalogRow(_ item: RewardCatalogItem) -> some View {
        let category = item.rewardCategory
        return HStack(spacing: 12) {
            Image(systemName: category.resolvedIcon)
                .font(.system(size: 14))
                .foregroundColor(category.color)
                .frame(width: 30, height: 30)
                .background(category.color.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)
                Text("\(item.pointsCost) pts")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }
            Spacer()
        }
    }

    private var suggestionsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
            ForEach(suggestions, id: \.title) { s in
                let alreadyAdded = vm.items.contains { $0.title == s.title }
                Button {
                    Task { await vm.addItem(category: s.category, title: s.title, cost: s.cost, description: nil) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: s.category.resolvedIcon)
                            .font(.system(size: 12))
                            .foregroundColor(s.category.color)
                        Text(s.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(alreadyAdded ? .textMuted : .memberBlue)
                        Spacer()
                        Text("\(s.cost)")
                            .font(.system(size: 10))
                            .foregroundColor(.textMuted)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(alreadyAdded ? Color.screenBg : Color(hex: "#EFF6FF"))
                    .cornerRadius(8)
                }
                .disabled(alreadyAdded)
            }
        }
        .padding(.horizontal, 16)
    }
}
