import SwiftUI

struct DotoWordmark: View {
    // .light = navy text on white bg (default, most screens)
    // .dark  = white text on navy bg (headers, splash)
    enum Style { case light, dark }

    var style: Style = .light
    var iconSize: CGFloat = 36

    private var textColor: Color {
        style == .dark ? .white : Color.appNavy
    }

    var body: some View {
        HStack(spacing: 10) {
            DotoLogoMark(size: iconSize)
            Text("doto")
                .font(.system(size: iconSize * 0.72, weight: .semibold, design: .default))
                .foregroundColor(textColor)
                .kerning(-0.5)
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        DotoWordmark(style: .light, iconSize: 40)
            .padding(24)
            .background(Color.white)

        DotoWordmark(style: .dark, iconSize: 40)
            .padding(24)
            .background(Color.appNavy)
    }
}
