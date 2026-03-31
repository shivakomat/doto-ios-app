import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = DashboardViewModel()

    @State private var showFAB = false
    @State private var showAddEvent = false
    @State private var showAddTask = false
    @State private var showAddItem = false
    @State private var showSettings = false
    @State private var showFamilyManage = false
    @State private var selectedEvent: EventSnapshot?

    private var isParent: Bool { authVM.currentProfile?.isParent == true }
    private var greeting: String {
        let name = authVM.currentProfile?.displayName.components(separatedBy: " ").first ?? ""
        return "\(Date().greeting), \(name) ☀"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                navHeader
                mainContent
            }
            .background(Color.screenBg.ignoresSafeArea())

            if isParent {
                fabButton
            }
        }
        .navigationBarHidden(true)
        .task { await vm.load() }
        .refreshable { await vm.load() }
        .sheet(isPresented: $showFAB) {
            FABBottomSheet(showAddEvent: $showAddEvent, showAddTask: $showAddTask, showAddItem: $showAddItem)
        }
        .sheet(isPresented: $showAddEvent, onDismiss: { Task { await vm.load() } }) {
            AddEditEventView(event: nil)
        }
        .sheet(isPresented: $showAddTask, onDismiss: { Task { await vm.load() } }) {
            AddEditTaskView(task: nil)
        }
        .sheet(isPresented: $showAddItem) {
            AddItemSheet(listId: nil)
        }
        .sheet(item: $selectedEvent) { snapshot in
            EventDetailSheet(event: snapshot.asDotoEvent(), onUpdate: { Task { await vm.load() } })
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showFamilyManage) {
            FamilyManageView()
        }
        .alert("Something went wrong",
               isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var navHeader: some View {
        ZStack {
            Color.appNavy.ignoresSafeArea(edges: .top)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(Date().fullDateString)
                        .font(.system(size: 11))
                        .foregroundColor(.appNavySub)
                }
                Spacer()
                if let profile = authVM.currentProfile {
                    Button { showSettings = true } label: {
                        AvatarView(name: profile.displayName, color: profile.color, size: 28)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(height: 44)
    }

    @ViewBuilder
    private var mainContent: some View {
        if vm.isLoading && vm.todaysEvents.isEmpty {
            LoadingView()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isParent {
                        avatarFilterRow
                        pendingApprovalsSection
                    }

                    pendingTasksCountCard

                    if !vm.filteredEvents.isEmpty {
                        upcomingEventsSection
                    }

                    if vm.filteredEvents.isEmpty && vm.pendingTasksCount == 0 && vm.pendingApprovals.isEmpty {
                        emptyStateSection
                    }
                }
                .padding(.bottom, 100)
            }
            .refreshable { await vm.load() }
        }
    }

    private var avatarFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                let currentId = authVM.currentProfile?.id
                let sorted = vm.members.sorted { a, b in
                    if a.id == currentId { return true }
                    if b.id == currentId { return false }
                    return a.displayName < b.displayName
                }

                ForEach(sorted) { member in
                    Button {
                        vm.toggleMemberFilter(member.id)
                    } label: {
                        AvatarView(
                            name: member.displayName,
                            color: member.color,
                            size: 26,
                            isActive: vm.selectedMemberId == member.id
                        )
                    }
                }

                Button {
                    showFamilyManage = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#E2E8F0"))
                            .frame(width: 26, height: 26)
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var pendingApprovalsSection: some View {
        if isParent && !vm.pendingApprovals.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("⏳ Pending approvals")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.memberAmber)
                    .padding(.horizontal)
                ForEach(vm.pendingApprovals) { approval in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(approval.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            Text("\(approval.pointsCost) pts")
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        Text("Review")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.memberBlue)
                    }
                    .padding(10)
                    .background(Color(hex: "#FEF3C7"))
                    .cornerRadius(7)
                    .padding(.horizontal)
                }
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.doneText)
                Text("Your family is all set for today ✓")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.doneText)
            }
            .padding(10)
            .background(Color.doneBg)
            .cornerRadius(7)
            .padding(.horizontal)
        }
    }

    private var pendingTasksCountCard: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(vm.pendingTasksCount)",
                label: "Pending Tasks",
                icon: "checkmark.circle.fill",
                iconColor: Color(hex: "#185FA5")
            )
            statCard(
                value: "\(vm.todaysEvents.count)",
                label: "Upcoming Events",
                icon: "calendar",
                iconColor: Color(hex: "#10B981")
            )
        }
        .padding(.horizontal)
    }

    private func statCard(value: String, label: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor.opacity(0.2))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming Events")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)
                .padding(.horizontal)

            let shown = Array(vm.filteredEvents.prefix(5))
            ForEach(shown) { event in
                EventPillView(event: event, members: vm.members)
                    .padding(.horizontal)
                    .onTapGesture { selectedEvent = event }
            }

            if vm.filteredEvents.count > 5 {
                Button("See all →") {}
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.memberBlue)
                    .padding(.horizontal)
            }
        }
    }

    private var emptyStateSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("👋")
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome to Doto")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.conflictText)
                    Text("Add your first event and task to get started.")
                        .font(.system(size: 11))
                        .foregroundColor(.conflictText)
                }
            }
            .padding(10)
            .background(Color.conflictBg)
            .cornerRadius(7)
            .padding(.horizontal)

            emptyCTACard(emoji: "📅", title: "Add your first event", subtitle: "Schedule a family event") {
                showAddEvent = true
            }
            emptyCTACard(emoji: "✅", title: "Assign a task", subtitle: "Create a task for a family member") {
                showAddTask = true
            }
            emptyCTACard(emoji: "👥", title: "Invite your partner", subtitle: "Share the mental load") {}
        }
    }

    private func emptyCTACard(emoji: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji).font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
            }
            .padding(14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundColor(.cardBorder)
            )
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }

    private var fabButton: some View {
        Button {
            showFAB = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(Color.memberBlue)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

struct EventPillView: View {
    let event: EventSnapshot
    let members: [MemberSnapshot]

    private var accentColor: Color {
        Color(hex: event.color ?? "#185FA5")
    }

    private var timeLabel: String {
        "\(event.startAt.relativeDue) · \(event.startAt.shortTime)"
    }

    private var assigneeNames: String {
        event.assignedTo.compactMap { id in
            members.first { $0.id == id }?.displayName
        }.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                HStack(spacing: 6) {
                    Text(timeLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                    if !assigneeNames.isEmpty {
                        Text("· \(assigneeNames)")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundColor(.textMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}
