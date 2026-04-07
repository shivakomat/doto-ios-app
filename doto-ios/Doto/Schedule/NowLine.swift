import SwiftUI

struct NowLine: View {
    let hourHeight: CGFloat
    let firstHour:  Int

    @State private var currentTime: Date = .now
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var yPosition: CGFloat {
        let cal  = Calendar.current
        let hour = cal.component(.hour,   from: currentTime)
        let min  = cal.component(.minute, from: currentTime)
        let total = Double(hour) + Double(min) / 60.0
        return CGFloat(total - Double(firstHour)) * hourHeight
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Circle()
                    .fill(Color(hex: "#E24B4A"))
                    .frame(width: 8, height: 8)
                    .offset(x: -4, y: yPosition - 4)

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
