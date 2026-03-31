import SwiftUI

struct FamilyCodeEntryView: View {
    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var preview: FamilyPreview?
    @State private var navigateToPreview = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter the invite code from your family member's Doto app.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            CodeInputView(code: $code)

            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#E24B4A"))
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(
                title: isLoading ? "Checking..." : "Continue →",
                isLoading: isLoading
            ) {
                Task { await lookupCode() }
            }
            .disabled(code.count < 6 || isLoading)

            Spacer()
        }
        .padding(.horizontal, 28)
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("Join a family")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $navigateToPreview) {
            if let preview {
                FamilyPreviewView(preview: preview)
            }
        }
    }

    private func lookupCode() async {
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do {
            let result: FamilyPreview = try await APIClient.shared.get(
                "/families/preview/\(code.uppercased())"
            )
            preview = result
            navigateToPreview = true
        } catch APIError.notFound {
            errorMessage = "Code not found. Check it and try again."
            code = ""
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }
}
