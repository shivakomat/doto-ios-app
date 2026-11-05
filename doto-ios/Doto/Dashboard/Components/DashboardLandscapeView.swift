import SwiftUI

/// Decorative landscape footer (sun, sparkles, hills, house, trees) drawn with
/// SwiftUI shapes. Meant to be pinned to the bottom edge of the dashboard.
struct DashboardLandscapeView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Sky
                Circle()
                    .fill(Color(hex: "#FBE7A1").opacity(0.45))
                    .frame(width: 58, height: 58)
                    .position(x: w * 0.70, y: h * 0.30)
                Circle()
                    .fill(Color(hex: "#FBE7A1"))
                    .frame(width: 38, height: 38)
                    .position(x: w * 0.70, y: h * 0.30)
                Sparkle()
                    .fill(Color(hex: "#F5C84C"))
                    .frame(width: 15, height: 15)
                    .position(x: w * 0.55, y: h * 0.26)
                Sparkle()
                    .fill(Color(hex: "#F5C84C").opacity(0.8))
                    .frame(width: 10, height: 10)
                    .position(x: w * 0.49, y: h * 0.52)

                // Hills (ground continues below the visible strip, behind the tab bar)
                Ellipse()
                    .fill(Color(hex: "#DCE8FA"))
                    .frame(width: w * 0.95, height: 110)
                    .position(x: w * 0.82, y: h * 0.98)
                Ellipse()
                    .fill(Color(hex: "#D6F0E2"))
                    .frame(width: w * 0.85, height: 90)
                    .position(x: w * 0.12, y: h * 1.02)
                Ellipse()
                    .fill(Color(hex: "#FCEBD3"))
                    .frame(width: w * 1.7, height: 70)
                    .position(x: w * 0.5, y: h + 20)
                Rectangle()
                    .fill(Color(hex: "#FCEBD3"))
                    .frame(width: w, height: 240)
                    .position(x: w * 0.5, y: h + 125)
                Ellipse()
                    .fill(Color(hex: "#CDEBD4"))
                    .frame(width: w * 0.75, height: 36)
                    .position(x: w * 0.36, y: h + 2)

                // Trees & bushes
                tree(size: 40, dark: "#3E9E74", light: "#6CC796")
                    .position(x: w * 0.09, y: h - 3 - 32)
                tree(size: 30, dark: "#4FB383", light: "#86D6A8")
                    .position(x: w * 0.19, y: h - 3 - 24)
                tree(size: 38, dark: "#2F8F6A", light: "#5DBB8A")
                    .position(x: w * 0.53, y: h - 3 - 30)
                bush(size: 18, color: "#4FB383")
                    .position(x: w * 0.25, y: h - 6)
                bush(size: 15, color: "#6CC796")
                    .position(x: w * 0.47, y: h - 5)

                house
                    .scaleEffect(0.8)
                    .position(x: w * 0.36, y: h - 4 - 37)
            }
            .frame(width: w, height: h)
        }
    }

    private var house: some View {
        ZStack {
            // Body
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(hex: "#FFF4DE"))
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color(hex: "#F1D6A4"), lineWidth: 1)
                )
                .frame(width: 66, height: 46)
                .offset(y: 20)

            // Chimney
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#E28A6E"))
                .frame(width: 9, height: 20)
                .offset(x: 20, y: -16)

            // Roof
            RoofShape()
                .fill(Color(hex: "#F6A58A"))
                .frame(width: 88, height: 38)
                .offset(y: -6)
            Image(systemName: "heart.fill")
                .font(.system(size: 9))
                .foregroundColor(Color(hex: "#FFE3D9"))
                .offset(y: -2)

            // Window + door
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#BFE0F5"))
                .frame(width: 13, height: 13)
                .offset(x: -18, y: 14)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: "#F9C97B"))
                .frame(width: 16, height: 26)
                .offset(x: 8, y: 33)
            Image(systemName: "heart.fill")
                .font(.system(size: 7))
                .foregroundColor(.white)
                .offset(x: 8, y: 30)
        }
        .frame(width: 90, height: 80)
    }

    private func tree(size: CGFloat, dark: String, light: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#8B5E3C"))
                .frame(width: size * 0.12, height: size * 0.5)
                .offset(y: size * 0.55)
            Circle()
                .fill(Color(hex: dark))
                .frame(width: size, height: size)
            Circle()
                .fill(Color(hex: light))
                .frame(width: size * 0.62, height: size * 0.62)
                .offset(x: -size * 0.12, y: -size * 0.12)
        }
    }

    private func bush(size: CGFloat, color: String) -> some View {
        Circle()
            .fill(Color(hex: color))
            .frame(width: size, height: size)
    }
}

private struct RoofShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - 6, y: rect.minY + 4))
        p.addQuadCurve(to: CGPoint(x: rect.midX + 6, y: rect.minY + 4),
                       control: CGPoint(x: rect.midX, y: rect.minY - 3))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct Sparkle: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: c)
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: c)
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: c)
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: c)
        p.closeSubpath()
        return p
    }
}
