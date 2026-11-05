import SwiftUI

struct ShoppingView: View {
    @StateObject private var vm = ShoppingViewModel()
    @State private var showAddItem = false
    @State private var showNewList = false
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var collapsedKeys: Set<String> = []
    @FocusState private var searchFocused: Bool
    let canManageLists: Bool

    init(canManageLists: Bool = true, vm: ShoppingViewModel = ShoppingViewModel()) {
        self.canManageLists = canManageLists
        _vm = StateObject(wrappedValue: vm)
    }

    private var listType: ShoppingListType { vm.selectedList?.type ?? .other }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private var isFiltering: Bool { isSearching && !trimmedQuery.isEmpty }

    private var visibleGroups: [ShoppingViewModel.ItemGroup] {
        guard isFiltering else { return vm.groupedItems }
        return vm.groupedItems.compactMap { group in
            let items = group.items.filter { $0.name.lowercased().contains(trimmedQuery) }
            return items.isEmpty ? nil : ShoppingViewModel.ItemGroup(key: group.key, title: group.title, items: items)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DashboardBackground()

            VStack(spacing: 0) {
                ScreenTitleBar(title: "Shopping Lists", subtitle: "Everything your family needs") {
                    DashboardCircleButton(systemName: isSearching ? "xmark" : "magnifyingglass",
                                          label: isSearching ? "Close search" : "Search items") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearching.toggle()
                            if !isSearching { searchText = "" }
                        }
                        searchFocused = isSearching
                    }
                    .disabled(vm.items.isEmpty)
                    .opacity(vm.items.isEmpty ? 0.5 : 1)

                    if canManageLists {
                        DashboardAddButton { showAddItem = true }
                    }
                }

                if isSearching { searchField }

                if !vm.lists.isEmpty { listChips }

                mainContent

                if canManageLists && vm.checkedCount > 0 {
                    clearCheckedButton
                }
            }

            if canManageLists {
                Button {
                    showAddItem = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.dashBlue)
                        .clipShape(Circle())
                        .shadow(color: Color.dashBlue.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
        .task { await vm.loadLists() }
        .sheet(isPresented: $showAddItem) {
            AddItemSheet(
                availableLists: vm.lists,
                preselectedListId: vm.selectedListId,
                vm: vm
            )
        }
        .sheet(isPresented: $showNewList) {
            NewListSheet(vm: vm)
        }
        .sheet(item: $vm.editingItem) { item in
            if let listId = vm.selectedListId {
                EditItemSheet(item: item, listId: listId, vm: vm)
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

    // MARK: - Content

    @ViewBuilder
    private var mainContent: some View {
        if (vm.isLoading && vm.lists.isEmpty) || (vm.isLoadingItems && vm.items.isEmpty) {
            LoadingView()
        } else if vm.lists.isEmpty {
            EmptyStateView(
                message: "No shopping lists yet",
                systemImage: "cart",
                cta: canManageLists ? "Create a list" : nil
            ) { showNewList = true }
        } else if vm.items.isEmpty {
            EmptyStateView(
                message: "No items in this list",
                systemImage: "cart",
                cta: canManageLists ? "Add one" : nil
            ) { showAddItem = true }
        } else if visibleGroups.isEmpty {
            EmptyStateView(message: "No items match \"\(searchText)\"", systemImage: "magnifyingglass")
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(visibleGroups.enumerated()), id: \.element.id) { index, group in
                        groupCard(group, index: index)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
                .padding(.bottom, 90)
            }
            .refreshable { await vm.loadItems() }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.dashSubtle)
            TextField("Search this list", text: $searchText)
                .focused($searchFocused)
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.textMuted)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.dashCardBorder, lineWidth: 1))
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    // MARK: - List chips

    private var listChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.lists) { list in
                    listChip(list)
                }
                if canManageLists {
                    Button {
                        showNewList = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                            Text("New list").font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.dashBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.7))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.dashBlueBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 2)
        }
        .padding(.bottom, 12)
    }

    private func listChip(_ list: ShoppingList) -> some View {
        let isActive = vm.selectedListId == list.id
        let accent = list.type.color
        return Button {
            Task { await vm.selectList(list.id) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: list.type.resolvedIcon)
                    .font(.system(size: 12, weight: .semibold))
                Text(list.name)
                    .font(.system(size: 13, weight: isActive ? .semibold : .medium))
                    .lineLimit(1)
            }
            .foregroundColor(isActive ? accent : .dashSubtle)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? accent.opacity(0.14) : Color(hex: "#E7ECF5"))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isActive ? accent.opacity(0.35) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if canManageLists {
                Button(role: .destructive) {
                    Task { await vm.deleteList(list.id) }
                } label: {
                    Label("Delete list", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Category card

    private func groupCard(_ group: ShoppingViewModel.ItemGroup, index: Int) -> some View {
        let style = ShoppingGroupStyle.style(for: group.key, listType: listType, index: index)
        let isCollapsed = collapsedKeys.contains(group.key) && !isFiltering

        return VStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if collapsedKeys.contains(group.key) { collapsedKeys.remove(group.key) }
                    else { collapsedKeys.insert(group.key) }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: style.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(style.color)
                        .frame(width: 36, height: 36)
                        .background(style.color.opacity(0.16))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.dashNavy)
                        Text("\(group.items.count) item\(group.items.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.dashSubtle)
                    }
                    Spacer()
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(style.color)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                VStack(spacing: 0) {
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { i, item in
                        itemRow(item, showDivider: i < group.items.count - 1)
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.dashCardBorder, lineWidth: 1)
                )
            }
        }
        .padding(10)
        .background(ZStack { Color.white; style.color.opacity(0.07) })
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(style.color.opacity(0.22), lineWidth: 1)
        )
    }

    // MARK: - Item row

    private func itemRow(_ item: ShoppingItem, showDivider: Bool) -> some View {
        let symbol = item.iconSymbol(for: listType)
        let tint = ShoppingGroupStyle.itemColor(for: symbol)

        return HStack(spacing: 8) {
            Button {
                Task { await vm.toggleItem(item) }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(item.isChecked ? Color.dashGreen : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(item.isChecked ? Color.dashGreen : Color(hex: "#C5CCD9"), lineWidth: 1.5)
                        )
                        .frame(width: 20, height: 20)
                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isChecked ? "Uncheck \(item.name)" : "Check \(item.name)")

            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .opacity(item.isChecked ? 0.5 : 1)

                Text(item.name + (item.quantity.map { " × \($0)" } ?? ""))
                    .font(.system(size: 14, weight: .medium))
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .textMuted : .dashNavy)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if canManageLists { vm.editingItem = item }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            if showDivider {
                Rectangle()
                    .fill(Color.dashCardBorder)
                    .frame(height: 1)
                    .padding(.horizontal, 10)
            }
        }
        .contextMenu {
            if canManageLists {
                Button {
                    vm.editingItem = item
                } label: {
                    Label("Edit item", systemImage: "pencil")
                }
                Menu {
                    ForEach(ShoppingListCategory.options(for: listType), id: \.value) { option in
                        Button {
                            Task { await vm.setCategory(item, option.value) }
                        } label: {
                            Text(option.label)
                        }
                    }
                } label: {
                    Label("Move to category", systemImage: "arrow.left.arrow.right")
                }
                Button(role: .destructive) {
                    Task { await vm.deleteItem(item) }
                } label: {
                    Label("Delete item", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Clear checked

    private var clearCheckedButton: some View {
        Button {
            Task { await vm.clearChecked() }
        } label: {
            Text("Clear \(vm.checkedCount) checked item\(vm.checkedCount == 1 ? "" : "s")")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.dashRed)
                .clipShape(Capsule())
                .shadow(color: Color.dashRed.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .padding(.leading, 18)
        .padding(.trailing, 88)
        .padding(.bottom, 12)
    }
}
