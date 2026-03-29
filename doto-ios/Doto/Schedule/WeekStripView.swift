import SwiftUI

struct WeekStripView: View {
    @ObservedObject var vm: ScheduleViewModel
    let dayLabels = ["S","M","T","W","T","F","S"]

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { idx, label in
                    Text(label)
                        .font(.system(size: 8))
                        .foregroundColor(.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 0) {
                ForEach(vm.currentWeekDates, id: \.self) { date in
                    dayCell(date: date)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width < 0 {
                        Task { await vm.nextWeek() }
                    } else {
                        Task { await vm.previousWeek() }
                    }
                }
        )
    }

    @ViewBuilder
    private func dayCell(date: Date) -> some View {
        let isToday    = Calendar.current.isDateInToday(date)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: vm.selectedDate)
        let hasEvents  = vm.events.contains { Calendar.current.isDate($0.startAt, inSameDayAs: date) }
        let dayNum     = Calendar.current.component(.day, from: date)

        Button {
            vm.selectedDate = date
        } label: {
            ZStack {
                if isToday {
                    Circle()
                        .fill(Color.memberBlue)
                        .frame(width: 24, height: 24)
                } else if isSelected {
                    Circle()
                        .fill(Color.selectedDayBg)
                        .frame(width: 24, height: 24)
                } else if hasEvents {
                    Circle()
                        .fill(Color.selectedDayBg)
                        .frame(width: 24, height: 24)
                }
                Text("\(dayNum)")
                    .font(.system(size: 9, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundColor(
                        isToday ? .white :
                        isSelected ? Color(hex: "#0C447C") :
                        hasEvents  ? Color(hex: "#0C447C") : .textSecondary
                    )
            }
            .frame(maxWidth: .infinity)
        }
    }
}
