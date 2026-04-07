import SwiftUI

struct DotoNavHeader: View {
    let title: String
    var trailing: (() -> AnyView)? = nil

    var body: some View {
        ZStack {
            Color.appNavy.ignoresSafeArea(edges: .top)
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                trailing?()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(height: 44)
    }
}

struct NavAddButton: View {
    var label: String = "Add"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(Color.appNavy)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(Capsule())
        }
    }
}
