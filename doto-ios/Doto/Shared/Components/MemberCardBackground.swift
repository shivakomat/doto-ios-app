import SwiftUI

struct MemberCardBackground: ViewModifier {
    let color: String
    func body(content: Content) -> some View {
        content
            .background(Color(hex: color).opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: color).opacity(0.4), lineWidth: 1)
            )
            .cornerRadius(8)
    }
}

extension View {
    func memberCardBackground(color: String) -> some View {
        self.modifier(MemberCardBackground(color: color))
    }
}
