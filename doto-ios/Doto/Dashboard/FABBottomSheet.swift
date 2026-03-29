import SwiftUI

struct FABBottomSheet: View {
    @Binding var showAddEvent: Bool
    @Binding var showAddTask: Bool
    @Binding var showAddItem: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#D1D5DB"))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 20)

            VStack(spacing: 1) {
                fabRow(emoji: "📅", title: "Add event") {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showAddEvent = true
                    }
                }
                Divider().padding(.leading, 60)
                fabRow(emoji: "✅", title: "Add task") {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showAddTask = true
                    }
                }
                Divider().padding(.leading, 60)
                fabRow(emoji: "🛒", title: "Add shopping item") {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showAddItem = true
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()
        }
        .background(Color.screenBg.ignoresSafeArea())
        .presentationDetents([.height(220)])
    }

    private func fabRow(emoji: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji).font(.system(size: 22))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
    }
}
