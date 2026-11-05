import SwiftUI

struct DotoLogoMark: View {
    var size: CGFloat = 48
    var framed: Bool = true

    static let cream  = Color(hex: "FBF1E6")
    static let blue   = Color(hex: "2F6FE0")
    static let peach  = Color(hex: "F2A97B")
    static let green  = Color(hex: "7FC49A")
    static let yellow = Color(hex: "F6D98A")

    var body: some View {
        // Circle geometry mirrors the 1024pt app icon; `size` is the full icon square.
        ZStack {
            if framed {
                RoundedRectangle(cornerRadius: size * 0.225)
                    .fill(Self.cream)
            }
            dot(Self.blue,   r: 0.133, x: -0.1406, y: -0.1367)
            dot(Self.peach,  r: 0.133, x:  0.1406, y: -0.1367)
            dot(Self.green,  r: 0.094, x: -0.1094, y:  0.1328)
            dot(Self.yellow, r: 0.094, x:  0.1094, y:  0.1328)
        }
        .frame(width: size, height: size)
    }

    private func dot(_ color: Color, r: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size * r * 2, height: size * r * 2)
            .offset(x: size * x, y: size * y)
    }
}

#Preview {
    HStack(spacing: 20) {
        DotoLogoMark(size: 80)
        DotoLogoMark(size: 48)
        DotoLogoMark(size: 32)
        DotoLogoMark(size: 80, framed: false)
    }
    .padding()
    .background(Color.white)
}
