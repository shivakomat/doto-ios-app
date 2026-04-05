import SwiftUI

struct DotoLogoMark: View {
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225)
                .fill(Color.appNavy)
                .frame(width: size, height: size)

            let parentR  = size * 0.1125
            let childR   = size * 0.08125
            let topY     = size * -0.125     // relative to centre
            let botY     = size *  0.1625
            let leftX    = size * -0.1625
            let rightX   = size *  0.125
            let cLeftX   = size * -0.25
            let cRightX  = size *  0.2

            // Parent dots
            Circle()
                .fill(Color.white)
                .frame(width: parentR * 2, height: parentR * 2)
                .offset(x: leftX, y: topY)
            Circle()
                .fill(Color.white)
                .frame(width: parentR * 2, height: parentR * 2)
                .offset(x: rightX, y: topY)

            // Child dots (slightly transparent)
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: childR * 2, height: childR * 2)
                .offset(x: cLeftX, y: botY)
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: childR * 2, height: childR * 2)
                .offset(x: cRightX, y: botY)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        DotoLogoMark(size: 80)
        DotoLogoMark(size: 48)
        DotoLogoMark(size: 32)
        DotoLogoMark(size: 20)
    }
    .padding()
    .background(Color.white)
}
