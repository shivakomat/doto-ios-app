import SwiftUI

struct EmptyStateView: View {
    let message: String
    var systemImage: String = "tray"
    var cta: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundColor(.textMuted)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            if let cta = cta, let action = action {
                Button(cta, action: action)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.memberBlue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
