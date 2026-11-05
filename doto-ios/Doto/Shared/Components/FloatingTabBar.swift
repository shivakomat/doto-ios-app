import SwiftUI

struct FloatingTabItem: Identifiable {
    let tab: DotoTab
    let title: String
    let icon: String
    var id: Int { tab.rawValue }
}

/// Floating white pill tab bar with a tinted highlight behind the selected tab.
struct FloatingTabBar: View {
    /// Height pages should reserve at the bottom so content clears the bar.
    static let reservedHeight: CGFloat = 66

    let items: [FloatingTabItem]
    @Binding var selection: DotoTab

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items) { item in
                let isSelected = item.tab == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = item.tab }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 19, weight: .regular))
                            .frame(height: 22)
                        Text(item.title)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundColor(isSelected ? .dashBlue : Color(hex: "#2B3350"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(isSelected ? Color.dashBlueTint : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.dashNavy.opacity(0.12), radius: 16, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.dashCardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 2)
    }
}

extension View {
    /// Reserves space at the bottom of a tab page for the floating tab bar.
    func floatingTabBarInset() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: FloatingTabBar.reservedHeight)
        }
    }
}
