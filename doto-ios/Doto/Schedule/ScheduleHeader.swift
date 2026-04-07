import SwiftUI

struct ScheduleHeader: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly: Bool
    let onAddTap:   () -> Void

    var headerTitle: String {
        let fmt = DateFormatter()
        switch vm.viewMode {
        case .day:
            fmt.dateFormat = "EEE d MMM"
            return fmt.string(from: vm.selectedDate)
        case .week:
            let days  = vm.daysInWeek(containing: vm.selectedDate)
            let start = days.first!
            let end   = days.last!
            let startFmt = DateFormatter(); startFmt.dateFormat = "d MMM"
            let endFmt   = DateFormatter(); endFmt.dateFormat   = "d MMM yyyy"
            return "\(startFmt.string(from: start)) – \(endFmt.string(from: end))"
        case .month:
            fmt.dateFormat = "MMMM yyyy"
            return fmt.string(from: vm.selectedDate)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        vm.navigateBack()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                }

                Text(headerTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .animation(.none, value: headerTitle)
                    .frame(maxWidth: .infinity)

                if !isReadOnly {
                    Button(action: onAddTap) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Add")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color.appNavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        vm.navigateForward()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                }
            }

            ScheduleModeSwitcher(selected: vm.viewMode) { mode in
                withAnimation(.easeInOut(duration: 0.2)) {
                    vm.setMode(mode)
                }
            }

            if !isReadOnly && !vm.members.isEmpty {
                MemberAvatarFilterRow(
                    members:  vm.members,
                    activeId: vm.activeFilterMemberId,
                    onTap:    { vm.toggleMemberFilter(id: $0) }
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.appNavy)
    }
}

struct ScheduleModeSwitcher: View {
    let selected: ScheduleMode
    let onSelect: (ScheduleMode) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ScheduleMode.allCases, id: \.self) { mode in
                Button(action: { onSelect(mode) }) {
                    Text(mode.rawValue)
                        .font(.system(size: 12, weight: selected == mode ? .semibold : .regular))
                        .foregroundColor(selected == mode ? Color.appNavy : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(selected == mode ? Color.white : Color.clear)
                        .cornerRadius(selected == mode ? 7 : 0)
                }
            }
        }
        .padding(2)
        .background(Color.white.opacity(0.12))
        .cornerRadius(9)
    }
}

struct MemberAvatarFilterRow: View {
    let members:  [Profile]
    let activeId: String?
    let onTap:    (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(members) { member in
                    Button { onTap(member.id) } label: {
                        AvatarView(
                            name:     member.displayName,
                            color:    member.color,
                            size:     24,
                            isActive: activeId == member.id
                        )
                        .opacity(activeId == nil || activeId == member.id ? 1.0 : 0.4)
                    }
                }
            }
        }
    }
}
