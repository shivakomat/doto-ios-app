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
