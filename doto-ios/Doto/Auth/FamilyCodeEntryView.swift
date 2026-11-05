import SwiftUI

struct FamilyCodeEntryView: View {
    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var preview: FamilyPreview?
    @State private var navigateToPreview = false

    var body: some View {
        AuthScreen(
            title: "Join a family",
            subtitle: "Enter the invite code from your family member's Doto app.",
            systemImage: "person.2.fill",
            footer: {
                AnyView(
                    PrimaryButton(
                        title: isLoading ? "Checking..." : "Continue →",
                        isLoading: isLoading
                    ) {
                        Task { await lookupCode() }
                    }
                    .disabled(code.count < 6 || isLoading)
                )
            }
        ) {
            VStack(spacing: 16) {
                CodeInputView(code: $code)

                if let err = errorMessage {
                    AuthMessage(text: err)
                }
            }
        }
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
