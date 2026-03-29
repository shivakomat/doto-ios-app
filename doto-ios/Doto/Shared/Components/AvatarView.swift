import SwiftUI

struct AvatarView: View {
    let name: String
    let color: String
    var size: CGFloat = 26
    var isActive: Bool = false

    private var initials: String {
        name.split(separator: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined().uppercased()
    }

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Color(hex: color))
            .clipShape(Circle())
            .overlay(
                Circle().stroke(
                    isActive ? Color(hex: color).opacity(0.8) : Color.clear,
                    lineWidth: 2
                )
            )
    }
}
