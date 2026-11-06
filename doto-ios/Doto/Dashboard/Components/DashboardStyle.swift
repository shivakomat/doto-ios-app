import SwiftUI

/// Rounded white surface used by every dashboard card.
struct DashboardCardModifier: ViewModifier {
    var radius: CGFloat = 14
    var fill: Color = .white
    var border: Color = .dashCardBorder

    func body(content: Content) -> some View {
        content
            .background(ZStack { Color.white; fill })
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(border, lineWidth: 1)
            )
            .shadow(color: Color.dashNavy.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func dashboardCard(radius: CGFloat = 14, fill: Color = .white, border: Color = .dashCardBorder) -> some View {
        modifier(DashboardCardModifier(radius: radius, fill: fill, border: border))
    }
}

/// Section heading used above dashboard cards (optionally with a trailing action).
struct DashboardSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.dashNavy)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.dashBlue)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Small capsule badge ("Overdue", "Today", "Tomorrow", ...).
struct DashboardBadge: View {
    let text: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }
}

/// Round white icon button used in screen title bars (search, etc.).
struct DashboardCircleButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.dashNavy)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.dashCardBorder, lineWidth: 1))
                .shadow(color: Color.dashNavy.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .accessibilityLabel(label)
    }
}

/// Blue "+ Add" capsule used in screen title bars.
struct DashboardAddButton: View {
    var title: String = "Add"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .frame(height: 40)
            .background(Color.dashBlue)
            .clipShape(Capsule())
            .shadow(color: Color.dashBlue.opacity(0.3), radius: 6, x: 0, y: 3)
        }
    }
}

/// Large title + subtitle with trailing actions.
struct ScreenTitleBar<Trailing: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.dashNavy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.dashSubtle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }
}

/// Accent colors cycled across tinted cards (goals, categories, tiles).
enum DashboardPalette {
    static let accents: [Color] = [
        Color(hex: "#F2711C"), Color(hex: "#1D9E75"), Color(hex: "#2F7DF6"),
        Color(hex: "#7A5AF8"), Color(hex: "#EC5C9A"), Color(hex: "#E8A317"),
        Color(hex: "#14A5B5")
    ]
    static func accent(_ index: Int) -> Color { accents[((index % accents.count) + accents.count) % accents.count] }
}

/// Pill segmented control with a solid blue selected segment.
struct DashboardSegmented<T: Hashable>: View {
    let options: [T]
    let title: (T) -> String
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selection = option }
                } label: {
                    Text(title(option))
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : Color(hex: "#6B7592"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.dashBlue : Color.clear)
                                .shadow(color: Color.dashBlue.opacity(isSelected ? 0.3 : 0), radius: 5, x: 0, y: 2)
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color(hex: "#E3E9F4"))
        .clipShape(Capsule())
    }
}

/// Soft sky gradient with the illustrated landscape sitting at the bottom of the
/// content area (the ground continues behind the floating tab bar).
struct DashboardBackground: View {
    var showLandscape: Bool = true

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#E9F1FF"), Color(hex: "#F5F8FF"), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if showLandscape {
                DashboardLandscapeView()
                    .frame(height: 110)
                    .allowsHitTesting(false)
            }
        }
    }
}

/// Small icon-only destructive chip that floats above the blue add button.
/// The count badge shows how many items it will clear.
struct FloatingClearButton: View {
    let count: Int
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "trash")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.dashRedText)
                .frame(width: 46, height: 46)
                .background(Color.white)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.dashRedBorder, lineWidth: 1.5))
                .shadow(color: Color.dashRed.opacity(0.2), radius: 8, x: 0, y: 4)
                .overlay(alignment: .topTrailing) {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Color.dashRed)
                        .clipShape(Capsule())
                        .offset(x: 4, y: -4)
                }
        }
        .accessibilityLabel(label)
    }
}
