import SwiftUI

/// Title block, Week/Month switcher and member filter.
struct ScheduleHeader: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly: Bool
    let onAddTap:   () -> Void
    let onSearchTap: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Schedule")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.dashNavy)
                    Text("Your family's day at a glance")
                        .font(.system(size: 13))
                        .foregroundColor(.dashSubtle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: 8)

                Button(action: onSearchTap) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.dashNavy)
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.dashCardBorder, lineWidth: 1))
                        .shadow(color: Color.dashNavy.opacity(0.05), radius: 6, x: 0, y: 2)
                }
                .accessibilityLabel("Search events")

                if !isReadOnly {
                    Button(action: onAddTap) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                            Text("Add")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 40)
                        .background(Color.dashBlue)
                        .clipShape(Capsule())
                        .shadow(color: Color.dashBlue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
            }

            ScheduleModeSwitcher(selected: vm.viewMode) { mode in
                withAnimation(.easeInOut(duration: 0.2)) {
                    vm.setMode(mode)
                }
            }

            if vm.members.count > 1 {
                HStack {
                    MemberAvatarFilterRow(
                        members:  vm.members,
                        activeId: vm.activeFilterMemberId,
                        onTap:    { vm.toggleMemberFilter(id: $0) }
                    )
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }
}

/// Seven day cards for the week containing the selected date.
struct ScheduleWeekStrip: View {
    @ObservedObject var vm: ScheduleViewModel
    var showDots: Bool = false

    private static let weekdayFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f
    }()

    var body: some View {
        HStack(spacing: 6) {
            ForEach(vm.daysInWeek(containing: vm.selectedDate), id: \.self) { day in
                card(for: day)
            }
        }
    }

    private func card(for day: Date) -> some View {
        let cal = Calendar.current
        let isToday    = cal.isDateInToday(day)
        let isSelected = cal.isDate(day, inSameDayAs: vm.selectedDate)
        let number     = cal.component(.day, from: day)

        return Button {
            vm.selectedDate = day
            Task { await vm.loadIfNeeded(for: day) }
        } label: {
            VStack(spacing: 4) {
                Text(Self.weekdayFmt.string(from: day))
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected || isToday ? .dashBlue : .dashSubtle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                ZStack {
                    Circle()
                        .fill(isSelected ? Color.dashBlue : Color.clear)
                        .frame(width: 28, height: 28)
                    Text("\(number)")
                        .font(.system(size: 15, weight: isSelected || isToday ? .bold : .semibold))
                        .foregroundColor(isSelected ? .white : (isToday ? .dashBlue : .dashNavy))
                }

                if showDots {
                    HStack(spacing: 3) {
                        ForEach(Array(vm.eventsForDay(day).prefix(3).enumerated()), id: \.offset) { _, e in
                            Circle()
                                .fill(e.isConflicting ? Color.conflictBorder : Color(hex: e.color ?? "#185FA5"))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.dashBlueTint : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.dashBlueBorder : Color.dashCardBorder, lineWidth: 1)
            )
            .shadow(color: Color.dashNavy.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

/// Current range title with the "Today" shortcut. Previous/next buttons step
/// by week or month.
struct ScheduleDateRow: View {
    @ObservedObject var vm: ScheduleViewModel

    private var title: String {
        let fmt = DateFormatter()
        switch vm.viewMode {
        case .week:
            let days = vm.daysInWeek(containing: vm.selectedDate)
            let startFmt = DateFormatter(); startFmt.dateFormat = "d MMM"
            let endFmt   = DateFormatter(); endFmt.dateFormat   = "d MMM yyyy"
            return "\(startFmt.string(from: days.first!)) – \(endFmt.string(from: days.last!))"
        case .month:
            fmt.dateFormat = "MMMM yyyy"
            return fmt.string(from: vm.selectedDate)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.dashNavy)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .animation(.none, value: title)

            Spacer(minLength: 8)

            chevron("chevron.left", label: "Previous") { vm.navigateBack() }
            chevron("chevron.right", label: "Next") { vm.navigateForward() }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    vm.selectedDate = .now
                }
                Task { await vm.loadIfNeeded(for: .now) }
            } label: {
                Text("Today")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.dashBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Color.dashBlueTint)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    private func chevron(_ name: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85), action)
        } label: {
            Image(systemName: name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.dashNavy)
                .frame(width: 30, height: 30)
                .background(Color.white)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.dashCardBorder, lineWidth: 1))
        }
        .accessibilityLabel(label)
    }
}

struct ScheduleModeSwitcher: View {
    let selected: ScheduleMode
    let onSelect: (ScheduleMode) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ScheduleMode.allCases, id: \.self) { mode in
                let isSelected = selected == mode
                Button(action: { onSelect(mode) }) {
                    Text(mode.rawValue)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .dashBlue : Color(hex: "#6B7592"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white : Color.clear)
                                .shadow(color: Color.dashNavy.opacity(isSelected ? 0.08 : 0), radius: 4, x: 0, y: 1)
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color(hex: "#E3E9F4"))
        .clipShape(Capsule())
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
                            size:     28,
                            isActive: activeId == member.id
                        )
                        .opacity(activeId == nil || activeId == member.id ? 1.0 : 0.4)
                    }
                }
            }
        }
    }
}
