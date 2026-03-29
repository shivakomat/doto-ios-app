import SwiftUI

struct ShoppingView: View {
    @StateObject private var vm = ShoppingViewModel()
    @State private var showAddItem = false
    @State private var showNewListInput = false
    @State private var newListName = ""

    var body: some View {
        VStack(spacing: 0) {
            DotoNavHeader(title: "Shopping", trailing: {
                AnyView(
                    Button("+ Add") { showAddItem = true }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.memberBlue)
                )
            })

            listTabStrip

            Divider()

            if vm.isLoadingItems && vm.items.isEmpty {
                LoadingView()
            } else if vm.items.isEmpty && !vm.lists.isEmpty {
                EmptyStateView(
                    message: "No items in this list",
                    systemImage: "cart",
                    cta: "Add one"
                ) { showAddItem = true }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(vm.groupedItems, id: \.category) { group in
                            categorySection(group)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.bottom, 80)
                }
                .refreshable { await vm.loadItems() }
            }

            if vm.checkedCount > 0 {
                clearCheckedButton
            }
        }
        .background(Color.screenBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await vm.loadLists() }
        .sheet(isPresented: $showAddItem, onDismiss: { Task { await vm.loadItems() } }) {
            AddItemSheet(listId: vm.selectedListId, onAdded: { Task { await vm.loadItems() } })
        }
        .alert("Something went wrong",
               isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var listTabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.lists) { list in
                    listTab(list)
                }

                if showNewListInput {
                    HStack(spacing: 4) {
                        TextField("List name", text: $newListName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                            .font(.system(size: 13))
                            .submitLabel(.done)
                            .onSubmit {
                                if !newListName.isEmpty {
                                    Task {
                                        await vm.createList(name: newListName)
                                        newListName = ""
                                        showNewListInput = false
                                    }
                                }
                            }
                        Button {
                            showNewListInput = false
                            newListName = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.textMuted)
                        }
                    }
                    .padding(.horizontal, 8)
                } else {
                    Button {
                        showNewListInput = true
                    } label: {
                        Text("+ New")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "#E2E8F0"))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    private func listTab(_ list: ShoppingList) -> some View {
        let isActive = vm.selectedListId == list.id
        return Button {
            Task { await vm.selectList(list.id) }
        } label: {
            Text(list.name)
                .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .white : .textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? Color.memberBlue : Color(hex: "#E2E8F0"))
                .cornerRadius(12)
        }
        .contextMenu {
            Button(role: .destructive) {
                Task { await vm.deleteList(list.id) }
            } label: {
                Label("Delete list", systemImage: "trash")
            }
        }
    }

    private func categorySection(_ group: (category: ShoppingCategory, items: [ShoppingItem])) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(group.category.emoji)
                    .font(.system(size: 13))
                Text(group.category.displayName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal)

            ForEach(group.items) { item in
                shoppingItemRow(item)
                    .padding(.horizontal)
            }
        }
    }

    private func shoppingItemRow(_ item: ShoppingItem) -> some View {
        HStack(spacing: 10) {
            Button {
                Task { await vm.toggleItem(item) }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(item.isChecked ? Color.clear : Color(hex: "#CBD5E1"), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if item.isChecked {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.doneText)
                            .frame(width: 18, height: 18)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(item.name + (item.quantity.map { " × \($0)" } ?? ""))
                        .font(.system(size: 13))
                        .strikethrough(item.isChecked)
                        .foregroundColor(item.isChecked ? .textMuted : .textPrimary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.white)
        .cornerRadius(6)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task { await vm.deleteItem(item) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var clearCheckedButton: some View {
        Button {
            Task { await vm.clearChecked() }
        } label: {
            Text("Clear \(vm.checkedCount) checked item\(vm.checkedCount == 1 ? "" : "s")")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "#EF4444"))
                .cornerRadius(10)
                .padding(.horizontal)
        }
        .padding(.bottom, 8)
        .background(Color.screenBg)
    }
}
