import SwiftUI

/// Bottom sheet for picking a task's recurrence rule.
/// Options: None / Daily / Weekly on <due weekday> / Custom days (weekday multi-select),
/// plus an Ends row (Never / On a date).
struct RepeatPickerSheet: View {
    @Binding var recurrence: TaskRecurrence
    /// Used to label "Weekly on Thu" and to seed a fresh custom day selection.
    let dueDate: Date
    /// When false (editing with scope=future), only the Ends rule can change —
    /// the API doesn't allow changing dueDate/repeatRule/repeatDays for a series.
    var frequencyEditable: Bool = true

    @State private var endsExpanded = false

    private var dueWeekday: Int {
        Calendar.current.component(.weekday, from: dueDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Repeat")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

            optionRow(label: "None", selected: recurrence.frequency == .none) {
                recurrence.frequency = .none
                recurrence.weekdays = []
                recurrence.endDate = nil
            }
            .disabled(!frequencyEditable)
            Divider().background(Color.cardBorder)
            optionRow(label: "Daily", selected: recurrence.frequency == .daily) {
                recurrence.frequency = .daily
                recurrence.weekdays = []
            }
            .disabled(!frequencyEditable)
            Divider().background(Color.cardBorder)
            optionRow(
                label: "Weekly on \(TaskRecurrence.weekdayShortNames[dueWeekday - 1])",
                selected: recurrence.frequency == .weekly
            ) {
                recurrence.frequency = .weekly
                recurrence.weekdays = []
            }
            .disabled(!frequencyEditable)
            Divider().background(Color.cardBorder)
            optionRow(label: "Custom days…", selected: recurrence.frequency == .custom) {
                recurrence.frequency = .custom
                if recurrence.weekdays.isEmpty {
                    recurrence.weekdays = [dueWeekday]
                }
            }
            .disabled(!frequencyEditable)

            if recurrence.frequency == .custom {
                dayPicker
            }

            if recurrence.isRecurring {
                Divider().background(Color.cardBorder)
                endsSection
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 8)
        .presentationDragIndicator(.visible)
    }

    // MARK: - Rows

    private func optionRow(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: selected ? .bold : .regular))
                    .foregroundColor(selected ? .memberBlue : .textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.memberBlue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var dayPicker: some View {
        HStack(spacing: 0) {
            ForEach(1...7, id: \.self) { weekday in
                let isSelected = recurrence.weekdays.contains(weekday)
                // The API requires a custom rule to include dueDate's day-of-week.
                let isLocked = weekday == dueWeekday
                Button {
                    if isSelected && !isLocked {
                        recurrence.weekdays.remove(weekday)
                    } else if !isSelected {
                        recurrence.weekdays.insert(weekday)
                    }
                } label: {
                    Text(TaskRecurrence.weekdayLetters[weekday - 1])
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? .white : .textSecondary)
                        .frame(width: 34, height: 34)
                        .background(isSelected ? Color.memberBlue : Color.screenBg)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .disabled(!frequencyEditable)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var endsSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation { endsExpanded.toggle() }
            } label: {
                HStack {
                    Text("Ends")
                        .font(.system(size: 16))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text(recurrence.endDate.map { $0.shortDate } ?? "Never")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.memberBlue)
                    Image(systemName: endsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textMuted)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if endsExpanded {
                endsOptionRow(label: "Never", selected: recurrence.endDate == nil) {
                    recurrence.endDate = nil
                }
                endsOptionRow(label: "On date", selected: recurrence.endDate != nil) {
                    if recurrence.endDate == nil {
                        recurrence.endDate = Calendar.current.date(byAdding: .month, value: 1, to: dueDate)
                    }
                }
                if recurrence.endDate != nil {
                    DatePicker(
                        "End date",
                        selection: Binding(
                            get: { recurrence.endDate ?? dueDate },
                            set: { recurrence.endDate = $0 }
                        ),
                        in: dueDate...,
                        displayedComponents: .date
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func endsOptionRow(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(selected ? .memberBlue : .textSecondary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.memberBlue)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
