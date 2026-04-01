import SwiftUI

struct RewardCatalogView: View {
    @StateObject private var vm = RewardCatalogViewModel()

    private let suggestions: [(emoji: String, title: String, cost: Int)] = [
        ("🎬", "Movie night",        100),
        ("🍕", "Choose dinner",       50),
        ("📱", "Extra screen time",   75),
        ("🛌", "Stay up late (Fri)",  80),
        ("🎡", "Day out",            300),
        ("👫", "Friend sleepover",   150),
        ("🧹", "Day off chores",      60),
        ("📚", "New book",            80),
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
                                HStack(spacing: 12) {
                                    Text(item.emoji ?? "🎯").font(.system(size: 18))
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
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await vm.deleteItem(item) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
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
                    Button("Done") { }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("+ Add") { vm.editingItem = nil; vm.showAddSheet = true }
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .task { await vm.load() }
            .sheet(isPresented: $vm.showAddSheet, onDismiss: { vm.editingItem = nil }) {
                AddCatalogItemSheet(editingItem: vm.editingItem) { emoji, title, cost in
                    Task {
                        if let editing = vm.editingItem {
                            await vm.updateItem(id: editing.id, emoji: emoji, title: title, cost: cost)
                        } else {
                            await vm.addItem(emoji: emoji, title: title, cost: cost)
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

    private var suggestionsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
            ForEach(suggestions, id: \.title) { s in
                let alreadyAdded = vm.items.contains { $0.title == s.title }
                Button {
                    Task { await vm.addItem(emoji: s.emoji, title: s.title, cost: s.cost) }
                } label: {
                    HStack(spacing: 6) {
                        Text(s.emoji).font(.system(size: 14))
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

struct AddCatalogItemSheet: View {
    let editingItem: RewardCatalogItem?
    let onSave: (String?, String, Int) -> Void

    @State private var title = ""
    @State private var emoji = ""
    @State private var cost = 50
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Reward title", text: $title)
                    TextField("Emoji (optional)", text: $emoji)
                }
                Section(header: Text("Points cost")) {
                    Stepper("\(cost) pts", value: $cost, in: 5...500, step: 5)
                }
            }
            .navigationTitle(editingItem == nil ? "Add reward" : "Edit reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(emoji.isEmpty ? nil : emoji, title, cost)
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let item = editingItem {
                    title = item.title
                    emoji = item.emoji ?? ""
                    cost = item.pointsCost
                }
            }
        }
    }
}
