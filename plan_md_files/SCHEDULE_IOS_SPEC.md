# Doto — Schedule iOS Spec
**Version:** 1.0
**Scope:** ScheduleView — Day, Week, and Month views with switcher, gestures, animations
**Replaces:** Screen 06 (ScheduleView) in core IOS_SPEC.md
**Depends on:** Core IOS_SPEC.md for shared components and colour system

---

## 1. Overview

The schedule screen mirrors the Apple Calendar experience — a segmented control
in the header switches between Day, Week, and Month views. All three views share
the same data (fetched once per month) and the same `selectedDate` state. Switching
views never triggers a new API call.

**Parent:** Full access — can add, edit, and delete events. Member filter row visible.
**Child:** Read-only — all family events visible, own events at full opacity, others dimmed.

---

## 2. File Structure

```
Schedule/
├── ScheduleView.swift               ← Root — contains switcher + routes to sub-views
├── ScheduleViewModel.swift          ← Shared state, data fetching, conflict detection
├── DayView.swift                    ← Day time grid
├── WeekView.swift                   ← 7-column week time grid
├── MonthView.swift                  ← Month grid + selected day event list
├── Components/
│   ├── ScheduleHeader.swift         ← Navy header with title + switcher + avatars
│   ├── TimeGridView.swift           ← Reusable time axis + event block layout
│   ├── EventBlock.swift             ← Positioned event block (Day + Week views)
│   ├── EventListRow.swift           ← Compact event row (Month view list)
│   ├── NowLine.swift                ← Red current-time indicator
│   ├── MonthGridView.swift          ← 7-col date grid with event dots
│   ├── EventDetailSheet.swift       ← Tap event → detail (parent: edit/delete)
│   ├── EventReadOnlySheet.swift     ← Tap event → read-only (child)
│   └── AddEditEventView.swift       ← Add / edit form (parent only)
```

---

## 3. Data Models

### 3.1 ScheduleMode

```swift
// Schedule/ScheduleView.swift
enum ScheduleMode: String, CaseIterable {
    case day   = "Day"
    case week  = "Week"
    case month = "Month"
}
```

### 3.2 DotoEvent (updated)

```swift
// Models/DotoEvent.swift
struct DotoEvent: Codable, Identifiable {
    let id:           String
    let familyId:     String
    var title:        String
    var startAt:      Date
    var endAt:        Date
    var location:     String?
    var notes:        String?
    var assignedTo:   [String]      // array of profile IDs
    var repeat:       String        // "none"|"daily"|"weekly"|"monthly"
    var isConflicting: Bool = false  // computed client-side, not from API

    var durationMinutes: Int {
        Int(endAt.timeIntervalSince(startAt) / 60)
    }

    var timeRangeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: startAt)) – \(f.string(from: endAt))"
    }

    var startHour: Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: startAt)
        return Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60.0
    }

    var durationHours: Double {
        Double(durationMinutes) / 60.0
    }
}
```

---

## 4. ScheduleViewModel

```swift
// Schedule/ScheduleViewModel.swift
@MainActor
class ScheduleViewModel: ObservableObject {

    // Shared across all three views
    @Published var selectedDate: Date = .now
    @Published var viewMode: ScheduleMode = .day
    @Published var events: [DotoEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Member filter (parent only)
    @Published var activeFilterMemberId: String?

    // Current loaded month range
    private var loadedMonthStart: Date?

    // Remembers last view in UserDefaults
    private let modeKey = "scheduleViewMode"

    init() {
        if let saved = UserDefaults.standard.string(forKey: modeKey),
           let mode = ScheduleMode(rawValue: saved) {
            viewMode = mode
        }
    }

    func setMode(_ mode: ScheduleMode) {
        viewMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: modeKey)
    }

    // ── Data fetching ─────────────────────────────────────────────────────

    func loadIfNeeded(for date: Date) async {
        let monthStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: date)
        )!
        // Skip if we already loaded this month
        if loadedMonthStart == monthStart && !events.isEmpty { return }

        await load(monthStart: monthStart)
    }

    func load(monthStart: Date) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        let monthEnd = Calendar.current.date(
            byAdding: DateComponents(month: 1, day: -1),
            to: monthStart
        )!

        let fmt = ISO8601DateFormatter()
        let from = fmt.string(from: monthStart)
        let to   = fmt.string(from: monthEnd)

        do {
            var fetched: [DotoEvent] = try await APIClient.shared.get(
                "/events", params: ["from": from, "to": to]
            )
            fetched = detectConflicts(fetched)
            events = fetched
            loadedMonthStart = monthStart
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ── Events for specific ranges ─────────────────────────────────────────

    func eventsForDay(_ date: Date) -> [DotoEvent] {
        let cal = Calendar.current
        return events
            .filter { cal.isDate($0.startAt, inSameDayAs: date) }
            .filter { memberFilter($0) }
            .sorted { $0.startAt < $1.startAt }
    }

    func eventsForWeek(containing date: Date) -> [Date: [DotoEvent]] {
        let weekDays = daysInWeek(containing: date)
        return Dictionary(uniqueKeysWithValues: weekDays.map { day in
            (day, eventsForDay(day))
        })
    }

    func eventsForMonth(containing date: Date) -> [Date: [DotoEvent]] {
        let days = daysInMonth(containing: date)
        return Dictionary(uniqueKeysWithValues: days.map { day in
            (day, eventsForDay(day))
        })
    }

    // ── Conflict detection ─────────────────────────────────────────────────

    func detectConflicts(_ events: [DotoEvent]) -> [DotoEvent] {
        return events.map { e1 in
            var e = e1
            e.isConflicting = events.contains { e2 in
                e1.id != e2.id &&
                e1.assignedTo.contains(where: { e2.assignedTo.contains($0) }) &&
                e1.startAt < e2.endAt &&
                e1.endAt   > e2.startAt
            }
            return e
        }
    }

    // ── Member filter ──────────────────────────────────────────────────────

    private func memberFilter(_ event: DotoEvent) -> Bool {
        guard let filterId = activeFilterMemberId else { return true }
        return event.assignedTo.contains(filterId)
    }

    func toggleMemberFilter(id: String) {
        activeFilterMemberId = activeFilterMemberId == id ? nil : id
    }

    // ── Date helpers ───────────────────────────────────────────────────────

    func daysInWeek(containing date: Date) -> [Date] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        let startOfWeek = cal.date(byAdding: .day, value: -(weekday - 1), to: date)!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    func daysInMonth(containing date: Date) -> [Date] {
        let cal  = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: date)
        comps.day = 1
        let start = cal.date(from: comps)!
        let range = cal.range(of: .day, in: .month, for: start)!
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    // ── Navigation ─────────────────────────────────────────────────────────

    func navigateForward() {
        let cal = Calendar.current
        switch viewMode {
        case .day:   selectedDate = cal.date(byAdding: .day,   value:  1, to: selectedDate)!
        case .week:  selectedDate = cal.date(byAdding: .day,   value:  7, to: selectedDate)!
        case .month: selectedDate = cal.date(byAdding: .month, value:  1, to: selectedDate)!
        }
        Task { await loadIfNeeded(for: selectedDate) }
    }

    func navigateBack() {
        let cal = Calendar.current
        switch viewMode {
        case .day:   selectedDate = cal.date(byAdding: .day,   value: -1, to: selectedDate)!
        case .week:  selectedDate = cal.date(byAdding: .day,   value: -7, to: selectedDate)!
        case .month: selectedDate = cal.date(byAdding: .month, value: -1, to: selectedDate)!
        }
        Task { await loadIfNeeded(for: selectedDate) }
    }
}
```

---

## 5. ScheduleView (Root)

```swift
// Schedule/ScheduleView.swift
struct ScheduleView: View {
    var isReadOnly: Bool = false       // true for children
    @StateObject private var vm = ScheduleViewModel()
    @State private var showAddEvent = false
    @State private var swipeOffset: CGFloat = 0
    @State private var transitioning = false

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                ScheduleHeader(
                    vm:          vm,
                    isReadOnly:  isReadOnly,
                    onAddTap:    { showAddEvent = true }
                )

                // Animated view switcher
                Group {
                    switch vm.viewMode {
                    case .day:
                        DayView(vm: vm, isReadOnly: isReadOnly)
                            .transition(.asymmetric(
                                insertion: .move(edge: swipeOffset < 0 ? .trailing : .leading),
                                removal:   .move(edge: swipeOffset < 0 ? .leading  : .trailing)
                            ))
                    case .week:
                        WeekView(vm: vm, isReadOnly: isReadOnly)
                            .transition(.asymmetric(
                                insertion: .move(edge: swipeOffset < 0 ? .trailing : .leading),
                                removal:   .move(edge: swipeOffset < 0 ? .leading  : .trailing)
                            ))
                    case .month:
                        MonthView(vm: vm, isReadOnly: isReadOnly)
                            .transition(.opacity)  // cross-fade for mode change
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: vm.selectedDate)
                .animation(.easeInOut(duration: 0.2), value: vm.viewMode)
            }
        }
        // Horizontal swipe gesture for time navigation
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    swipeOffset = value.translation.width
                }
                .onEnded { value in
                    let velocity = value.predictedEndTranslation.width - value.translation.width
                    let threshold: CGFloat = 50
                    if value.translation.width < -threshold || velocity < -200 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            vm.navigateForward()
                        }
                    } else if value.translation.width > threshold || velocity > 200 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            vm.navigateBack()
                        }
                    }
                    swipeOffset = 0
                }
        )
        .sheet(isPresented: $showAddEvent) {
            AddEditEventView(
                selectedDate: vm.selectedDate,
                onSave: { Task { await vm.load(monthStart: vm.selectedDate.monthStart) } }
            )
        }
        .task { await vm.loadIfNeeded(for: vm.selectedDate) }
    }
}
```

---

## 6. ScheduleHeader

```swift
// Schedule/Components/ScheduleHeader.swift
struct ScheduleHeader: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly: Bool
    let onAddTap:   () -> Void

    // Members from environment for the avatar filter row
    @EnvironmentObject var authVM: AuthViewModel

    var headerTitle: String {
        let cal = Calendar.current
        let fmt = DateFormatter()
        switch vm.viewMode {
        case .day:
            fmt.dateFormat = "EEE d MMM"
            return fmt.string(from: vm.selectedDate)
        case .week:
            let days   = vm.daysInWeek(containing: vm.selectedDate)
            let start  = days.first!
            let end    = days.last!
            fmt.dateFormat = "d MMM"
            let endFmt = DateFormatter(); endFmt.dateFormat = "d MMM yyyy"
            return "\(fmt.string(from: start)) – \(endFmt.string(from: end))"
        case .month:
            fmt.dateFormat = "MMMM yyyy"
            return fmt.string(from: vm.selectedDate)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.appNavy

                VStack(spacing: 8) {
                    // Title row
                    HStack {
                        Text(headerTitle)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        if !isReadOnly {
                            Button("+ Add") { onAddTap() }
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#60A5FA"))
                        }
                    }

                    // Segmented switcher
                    ScheduleModeSwitcher(selected: vm.viewMode) { mode in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.setMode(mode)
                        }
                    }

                    // Member avatar filter row (parent only)
                    if !isReadOnly {
                        MemberFilterRow(
                            members:  authVM.currentProfile.flatMap { _ in [] } ?? [],
                            activeId: vm.activeFilterMemberId,
                            onTap:    { vm.toggleMemberFilter(id: $0) }
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
    }
}

// Custom segmented control on the navy header
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
                        .background(
                            selected == mode
                                ? Color.white
                                : Color.clear
                        )
                        .cornerRadius(selected == mode ? 7 : 0)
                }
            }
        }
        .padding(2)
        .background(Color.white.opacity(0.12))
        .cornerRadius(9)
    }
}
```

---

## 7. DayView

```swift
// Schedule/DayView.swift
struct DayView: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly: Bool

    @State private var selectedEvent: DotoEvent?
    @State private var showDetail    = false

    // How many points tall each hour is
    let hourHeight: CGFloat = 56.0
    let firstHour:  Int     = 7     // grid starts at 7 AM

    var dayEvents: [DotoEvent] {
        vm.eventsForDay(vm.selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Day label
            HStack {
                Text(vm.selectedDate.fullDayLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.screenBg)

            // Scrollable time grid
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    TimeGridView(
                        firstHour:   firstHour,
                        lastHour:    22,
                        hourHeight:  hourHeight,
                        events:      dayEvents,
                        isReadOnly:  isReadOnly,
                        currentProfileId: nil,  // nil in parent mode — no dimming
                        onEventTap: { event in
                            selectedEvent = event
                            showDetail    = true
                        }
                    )
                    .id("timegrid")
                }
                .onAppear {
                    // Scroll to 1 hour before first event, or 8 AM, or now-1h for today
                    let scrollTo = scrollTarget
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("timegrid", anchor: .init(
                                x: 0,
                                y: CGFloat(scrollTo - firstHour) * hourHeight / (CGFloat(22 - firstHour) * hourHeight)
                            ))
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            if isReadOnly {
                EventReadOnlySheet(event: event, members: [])
            } else {
                EventDetailSheet(event: event, onUpdate: {
                    Task { await vm.load(monthStart: vm.selectedDate.monthStart) }
                })
            }
        }
        // Tap empty slot → add event (parent only)
        .overlay(
            isReadOnly ? nil : Color.clear
                .contentShape(Rectangle())
                .gesture(TapGesture().onEnded { })  // handled inside TimeGridView
        )
    }

    private var scrollTarget: Int {
        let cal  = Calendar.current
        let isToday = cal.isDateInToday(vm.selectedDate)
        if isToday {
            return max(firstHour, cal.component(.hour, from: .now) - 1)
        }
        if let first = dayEvents.first {
            return max(firstHour, Int(first.startHour) - 1)
        }
        return 8
    }
}
```

---

## 8. TimeGridView (Shared Component)

Used by both `DayView` and `WeekView`. Handles event block positioning,
conflict side-by-side layout, and the now line.

```swift
// Schedule/Components/TimeGridView.swift
struct TimeGridView: View {
    let firstHour:          Int
    let lastHour:           Int
    let hourHeight:         CGFloat
    let events:             [DotoEvent]
    let isReadOnly:         Bool
    let currentProfileId:   String?   // if set, dim events not assigned to this ID
    let onEventTap:         (DotoEvent) -> Void

    // Column width for positioning
    // (set by GeometryReader in the calling view)

    private let timeColWidth: CGFloat = 40

    var body: some View {
        GeometryReader { geo in
            let colWidth = geo.size.width - timeColWidth
            let totalHeight = CGFloat(lastHour - firstHour) * hourHeight

            ZStack(alignment: .topLeading) {
                // Hour row backgrounds + lines
                VStack(spacing: 0) {
                    ForEach(firstHour..<lastHour, id: \.self) { hour in
                        HStack(spacing: 0) {
                            // Time label
                            Text(hourLabel(hour))
                                .font(.system(size: 10))
                                .foregroundColor(isNowHour(hour)
                                    ? Color(hex: "#E24B4A")
                                    : Color.textMuted)
                                .frame(width: timeColWidth, alignment: .trailing)
                                .padding(.trailing, 6)

                            // Hour divider line
                            Rectangle()
                                .fill(Color.cardBorder)
                                .frame(height: 0.5)
                        }
                        .frame(height: hourHeight)
                    }
                }

                // Event blocks
                ForEach(layoutGroups(), id: \.id) { item in
                    EventBlock(
                        event:       item.event,
                        isReadOnly:  isReadOnly,
                        isDimmed:    shouldDim(item.event),
                        onTap:       { onEventTap(item.event) }
                    )
                    .frame(
                        width:  colWidth * item.widthFraction - 2,
                        height: max(hourHeight * CGFloat(item.event.durationHours), 20)
                    )
                    .offset(
                        x: timeColWidth + colWidth * item.xFraction + 1,
                        y: yOffset(for: item.event)
                    )
                }

                // Now line (today only)
                if Calendar.current.isDateInToday(Date()) {
                    NowLine(hourHeight: hourHeight, firstHour: firstHour)
                        .offset(x: timeColWidth, y: 0)
                        .frame(width: colWidth)
                }
            }
            .frame(height: totalHeight)
        }
        .frame(height: CGFloat(lastHour - firstHour) * hourHeight)
    }

    // ── Layout helpers ─────────────────────────────────────────────────────

    struct LayoutItem: Identifiable {
        let id:            String
        let event:         DotoEvent
        let xFraction:     CGFloat   // 0.0 – 1.0 horizontal offset fraction
        let widthFraction: CGFloat   // 0.0 – 1.0 width fraction
    }

    // Group overlapping events and assign columns
    func layoutGroups() -> [LayoutItem] {
        var result: [LayoutItem] = []
        var remaining = events.sorted { $0.startAt < $1.startAt }

        while !remaining.isEmpty {
            let event   = remaining.removeFirst()
            var cluster = [event]

            // Find all events that overlap with any event in the cluster
            var i = 0
            while i < remaining.count {
                let candidate = remaining[i]
                let overlaps  = cluster.contains { e in
                    e.startAt < candidate.endAt && e.endAt > candidate.startAt
                }
                if overlaps {
                    cluster.append(remaining.remove(at: i))
                } else {
                    i += 1
                }
            }

            let cols = cluster.count
            for (index, e) in cluster.enumerated() {
                result.append(LayoutItem(
                    id:            e.id,
                    event:         e,
                    xFraction:     CGFloat(index) / CGFloat(cols),
                    widthFraction: 1.0 / CGFloat(cols)
                ))
            }
        }
        return result
    }

    func yOffset(for event: DotoEvent) -> CGFloat {
        CGFloat(event.startHour - Double(firstHour)) * hourHeight
    }

    func shouldDim(_ event: DotoEvent) -> Bool {
        guard let id = currentProfileId else { return false }
        return !event.assignedTo.contains(id)
    }

    func hourLabel(_ hour: Int) -> String {
        if hour == 12 { return "12 PM" }
        if hour == 0  { return "12 AM" }
        return hour < 12 ? "\(hour) AM" : "\(hour - 12) PM"
    }

    func isNowHour(_ hour: Int) -> Bool {
        Calendar.current.component(.hour, from: .now) == hour
    }
}
```

---

## 9. EventBlock

```swift
// Schedule/Components/EventBlock.swift
struct EventBlock: View {
    let event:      DotoEvent
    let isReadOnly: Bool
    let isDimmed:   Bool
    let onTap:      () -> Void

    // Resolve member colour from the first assigned member
    // Pass members array from parent if needed
    var borderColor: Color {
        event.isConflicting
            ? Color.conflictBorder
            : Color(hex: "#185FA5")  // fallback — override with member colour
    }

    var bgColor: Color {
        event.isConflicting
            ? Color.conflictBg
            : borderColor.opacity(0.1)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Left colour bar
                Rectangle()
                    .fill(borderColor)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 1) {
                    Text((event.isConflicting ? "⚠ " : "") + event.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(event.isConflicting ? Color.conflictText : borderColor)
                        .lineLimit(2)

                    if event.durationMinutes > 30 {
                        Text(event.timeRangeLabel)
                            .font(.system(size: 8))
                            .foregroundColor(event.isConflicting
                                ? Color.conflictText.opacity(0.8)
                                : Color.textMuted)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)

                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .background(
            event.isConflicting
                ? Color.conflictBg
                : bgColor
        )
        .overlay(
            event.isConflicting
                ? RoundedRectangle(cornerRadius: 4).stroke(Color.conflictBorder, lineWidth: 1)
                : nil
        )
        .cornerRadius(4)
        .opacity(isDimmed ? 0.5 : 1.0)
    }
}
```

---

## 10. NowLine

```swift
// Schedule/Components/NowLine.swift
struct NowLine: View {
    let hourHeight: CGFloat
    let firstHour:  Int

    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var currentTime: Date = .now

    var yPosition: CGFloat {
        let cal   = Calendar.current
        let hour  = cal.component(.hour,   from: currentTime)
        let min   = cal.component(.minute, from: currentTime)
        let total = Double(hour) + Double(min) / 60.0
        return CGFloat(total - Double(firstHour)) * hourHeight
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Dot on left
                Circle()
                    .fill(Color(hex: "#E24B4A"))
                    .frame(width: 8, height: 8)
                    .offset(x: -4, y: yPosition - 4)

                // Line
                Rectangle()
                    .fill(Color(hex: "#E24B4A"))
                    .frame(height: 1.5)
                    .frame(width: geo.size.width)
                    .offset(y: yPosition)
            }
        }
        .onReceive(timer) { _ in currentTime = .now }
    }
}
```

---

## 11. WeekView

```swift
// Schedule/WeekView.swift
struct WeekView: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly: Bool

    let hourHeight: CGFloat = 40.0
    let firstHour:  Int     = 7
    let timeColWidth: CGFloat = 28

    var weekDays: [Date] { vm.daysInWeek(containing: vm.selectedDate) }

    var body: some View {
        VStack(spacing: 0) {
            // Day header row — S M T W T F S with date numbers
            HStack(spacing: 0) {
                // Empty space above time labels
                Color.clear.frame(width: timeColWidth)

                ForEach(weekDays, id: \.self) { day in
                    let isToday  = Calendar.current.isDateInToday(day)
                    let isSelect = Calendar.current.isDate(day, inSameDayAs: vm.selectedDate)
                    let dayNum   = Calendar.current.component(.day, from: day)
                    let dayLabel = day.shortWeekdayLabel

                    Button {
                        // Tap day header → switch to Day view for that day
                        vm.selectedDate = day
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.setMode(.day)
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text(dayLabel)
                                .font(.system(size: 9))
                                .foregroundColor(isToday ? Color.memberBlue : Color.textMuted)

                            ZStack {
                                if isToday {
                                    Circle()
                                        .fill(Color.memberBlue)
                                        .frame(width: 20, height: 20)
                                } else if isSelect {
                                    Circle()
                                        .fill(Color.cardBorder)
                                        .frame(width: 20, height: 20)
                                }
                                Text("\(dayNum)")
                                    .font(.system(size: 10, weight: isToday ? .bold : .regular))
                                    .foregroundColor(isToday ? .white : Color.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .background(isToday ? Color.memberBlue.opacity(0.05) : Color.clear)
                }
            }
            .background(Color.white)
            .overlay(Divider(), alignment: .bottom)

            // Scrollable time grid — 7 columns
            ScrollView(.vertical, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Time labels column
                    VStack(spacing: 0) {
                        ForEach(firstHour..<22, id: \.self) { hour in
                            Text(hourLabelShort(hour))
                                .font(.system(size: 9))
                                .foregroundColor(isNowHour(hour) ? Color(hex: "#E24B4A") : Color.textMuted)
                                .frame(width: timeColWidth, height: hourHeight, alignment: .topTrailing)
                                .padding(.trailing, 4)
                        }
                    }

                    // 7 day columns
                    ForEach(weekDays, id: \.self) { day in
                        WeekDayColumn(
                            day:             day,
                            events:          vm.eventsForDay(day),
                            hourHeight:      hourHeight,
                            firstHour:       firstHour,
                            isReadOnly:      isReadOnly,
                            onEventTap:      { event in
                                vm.selectedDate = day
                                // Show event detail sheet
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .overlay(Divider(), alignment: .leading)
                    }
                }
            }
        }
    }

    func hourLabelShort(_ hour: Int) -> String {
        if hour == 12 { return "12" }
        return hour < 12 ? "\(hour)" : "\(hour - 12)"
    }

    func isNowHour(_ hour: Int) -> Bool {
        Calendar.current.component(.hour, from: .now) == hour
    }
}

struct WeekDayColumn: View {
    let day:         Date
    let events:      [DotoEvent]
    let hourHeight:  CGFloat
    let firstHour:   Int
    let isReadOnly:  Bool
    let onEventTap:  (DotoEvent) -> Void

    var isToday: Bool { Calendar.current.isDateInToday(day) }

    var body: some View {
        ZStack(alignment: .top) {
            // Hour lines
            VStack(spacing: 0) {
                ForEach(firstHour..<22, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: hourHeight)
                        .overlay(Divider(), alignment: .bottom)
                }
            }

            // Today column tint
            if isToday {
                Color.memberBlue.opacity(0.03)
            }

            // Event blocks — stacked, overlapping handled by width fractions
            ForEach(events) { event in
                let topOffset = CGFloat(event.startHour - Double(firstHour)) * hourHeight
                let height    = max(hourHeight * CGFloat(event.durationHours), 18)
                EventBlock(
                    event:      event,
                    isReadOnly: isReadOnly,
                    isDimmed:   false,
                    onTap:      { onEventTap(event) }
                )
                .frame(height: height)
                .offset(y: topOffset)
            }

            // Now line (today only)
            if isToday {
                NowLine(hourHeight: hourHeight, firstHour: firstHour)
            }
        }
    }
}
```

---

## 12. MonthView

```swift
// Schedule/MonthView.swift
struct MonthView: View {
    @ObservedObject var vm: ScheduleViewModel
    let isReadOnly: Bool

    @State private var selectedEvent: DotoEvent?

    var body: some View {
        VStack(spacing: 0) {
            // Full month grid
            MonthGridView(
                date:        vm.selectedDate,
                eventsByDay: vm.eventsForMonth(containing: vm.selectedDate),
                selectedDate: Binding(
                    get: { vm.selectedDate },
                    set: { vm.selectedDate = $0 }
                ),
                onDoubleTap: { date in
                    // Double-tap → switch to Day view
                    vm.selectedDate = date
                    withAnimation(.easeOut(duration: 0.3)) {
                        vm.setMode(.day)
                    }
                }
            )
            .background(Color.white)

            Divider()

            // Selected day label
            HStack {
                Text(vm.selectedDate.fullDayLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.screenBg)

            // Compact event list for selected day
            let dayEvents = vm.eventsForDay(vm.selectedDate)
            if dayEvents.isEmpty {
                Text("No events")
                    .font(.system(size: 13))
                    .foregroundColor(Color.textMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(20)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(dayEvents) { event in
                            EventListRow(event: event)
                                .onTapGesture {
                                    selectedEvent = event
                                }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            if isReadOnly {
                EventReadOnlySheet(event: event, members: [])
            } else {
                EventDetailSheet(event: event, onUpdate: {
                    Task { await vm.load(monthStart: vm.selectedDate.monthStart) }
                })
            }
        }
    }
}
```

---

## 13. MonthGridView

```swift
// Schedule/Components/MonthGridView.swift
struct MonthGridView: View {
    let date:         Date
    let eventsByDay:  [Date: [DotoEvent]]
    @Binding var selectedDate: Date
    let onDoubleTap:  (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var gridDays: [Date?] {
        let cal       = Calendar.current
        let firstDay  = date.monthStart
        let weekday   = cal.component(.weekday, from: firstDay) - 1  // 0=Sun
        let daysInMo  = cal.range(of: .day, in: .month, for: firstDay)!.count
        let total     = weekday + daysInMo
        let padded    = total + (7 - total % 7) % 7

        return (0..<padded).map { i in
            i < weekday ? nil
                : cal.date(byAdding: .day, value: i - weekday, to: firstDay)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Day-of-week headers
            HStack(spacing: 0) {
                ForEach(dayLabels, id: \.self) { l in
                    Text(l)
                        .font(.system(size: 10))
                        .foregroundColor(Color.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
            .overlay(Divider(), alignment: .bottom)

            // Date grid
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                    if let day = day {
                        MonthDayCell(
                            day:          day,
                            events:       eventsByDay[day] ?? [],
                            isSelected:   Calendar.current.isDate(day, inSameDayAs: selectedDate),
                            isToday:      Calendar.current.isDateInToday(day),
                            onTap:        { selectedDate = day },
                            onDoubleTap:  { onDoubleTap(day) }
                        )
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
    }
}

struct MonthDayCell: View {
    let day:         Date
    let events:      [DotoEvent]
    let isSelected:  Bool
    let isToday:     Bool
    let onTap:       () -> Void
    let onDoubleTap: () -> Void

    // Up to 3 event dots
    var dots: [(color: String, isConflict: Bool)] {
        Array(events.prefix(3).map { e in
            (color: "#185FA5", isConflict: e.isConflicting)  // colour resolved from member
        })
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(Color.memberBlue)
                        .frame(width: 24, height: 24)
                } else if isSelected {
                    Circle()
                        .fill(Color.cardBorder)
                        .frame(width: 24, height: 24)
                }
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.system(size: 11, weight: isToday ? .bold : .regular))
                    .foregroundColor(
                        isToday    ? .white :
                        isSelected ? Color.textPrimary :
                        Color.textSecondary
                    )
            }

            // Event dots
            HStack(spacing: 2) {
                ForEach(dots.indices, id: \.self) { i in
                    Circle()
                        .fill(dots[i].isConflict
                            ? Color.conflictBorder
                            : Color(hex: dots[i].color))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 44)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onDoubleTap() }
        .onTapGesture(count: 1) { onTap() }
    }
}
```

---

## 14. EventListRow (Month View)

```swift
// Schedule/Components/EventListRow.swift
struct EventListRow: View {
    let event: DotoEvent

    var body: some View {
        HStack(spacing: 10) {
            // Coloured left bar
            Rectangle()
                .fill(event.isConflicting ? Color.conflictBorder : Color.memberBlue)
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 2) {
                Text((event.isConflicting ? "⚠ " : "") + event.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(event.isConflicting ? Color.conflictText : Color.textPrimary)

                Text(event.timeRangeLabel)
                    .font(.system(size: 11))
                    .foregroundColor(event.isConflicting ? Color.conflictText.opacity(0.8) : Color.textMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(event.isConflicting ? Color.conflictBg : Color.white)
        .overlay(Divider(), alignment: .bottom)
    }
}
```

---

## 15. EventDetailSheet (Parent)

```swift
// Schedule/Components/EventDetailSheet.swift
struct EventDetailSheet: View {
    let event:    DotoEvent
    let onUpdate: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showEdit   = false
    @State private var showDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.cardBorder)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            // Header
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.memberBlue)   // resolve from member
                        .frame(width: 10, height: 10)
                        .padding(.top, 3)
                    Text(event.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                }
                Spacer()
                HStack(spacing: 16) {
                    Button("Edit") { showEdit = true }
                        .font(.system(size: 13))
                        .foregroundColor(Color.memberBlue)
                    Button("Delete") { showDelete = true }
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#E24B4A"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            // Detail rows
            VStack(spacing: 14) {
                DetailRow(icon: "clock", text: "\(event.startAt.fullDayLabel)\n\(event.timeRangeLabel) · \(event.durationMinutes) min")
                if let loc = event.location {
                    DetailRow(icon: "mappin", text: loc)
                }
                // Assignees row — resolve names from profile list
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            // Conflict warning
            if event.isConflicting {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.conflictBorder)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scheduling conflict")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.conflictText)
                        Button("Resolve conflict →") { }
                            .font(.system(size: 12))
                            .foregroundColor(Color.memberBlue)
                    }
                }
                .padding(12)
                .background(Color.conflictBg)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.conflictBorder, lineWidth: 1))
                .cornerRadius(8)
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            Spacer()
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showEdit) {
            AddEditEventView(existingEvent: event, onSave: { dismiss(); onUpdate() })
        }
        .confirmationDialog("Delete event?", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                Task {
                    let _: EmptyResponse = try await APIClient.shared.delete("/events/\(event.id)")
                    onUpdate()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct DetailRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(Color.textMuted)
                .frame(width: 18)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
```

---

## 16. Date Extensions

```swift
// Shared/Extensions/Date+Schedule.swift
extension Date {
    var monthStart: Date {
        Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: self)
        )!
    }

    var fullDayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: self)
    }

    var shortWeekdayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return String(f.string(from: self).prefix(1))
    }
}
```

---

## 17. Parent vs Child — Full Comparison

| Element | Parent | Child |
|---|---|---|
| Segmented switcher (Day/Week/Month) | ✅ | ✅ |
| "+ Add" button in header | ✅ | ❌ |
| Member avatar filter row | ✅ | ❌ |
| Own events opacity | Full | Full |
| Others' events opacity | Full | 50% |
| "You" label on own events | ❌ | ✅ |
| Tap event | Edit/Delete sheet | Read-only sheet |
| Double-tap date (Month) | Switch to Day view | Switch to Day view |
| Tap empty time slot | Opens add form | No action |
| Conflict warning | Shown + "Resolve →" | Shown, no action |
| Swipe left/right navigate | ✅ | ✅ |

---

## 18. API Call Summary

| When | Endpoint | Params |
|---|---|---|
| Tab opens | `GET /api/events` | `from=monthStart&to=monthEnd` |
| Navigate to prev/next month | `GET /api/events` | Updated month range |
| Navigate within same month | No call — filter in memory | — |
| Add event | `POST /api/events` | Full event body |
| Edit event | `PUT /api/events/:id` | Updated fields |
| Delete event | `DELETE /api/events/:id` | — |
