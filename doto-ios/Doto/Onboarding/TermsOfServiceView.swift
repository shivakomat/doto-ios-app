import SwiftUI
import WebKit

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationView {
            WebView(html: TermsHTML.content, onOpenExternal: { url in
                openURL(url)
            })
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct WebView: UIViewRepresentable {
    let html: String
    let onOpenExternal: (URL) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .systemBackground
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onOpenExternal: onOpenExternal)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onOpenExternal: (URL) -> Void

        init(onOpenExternal: @escaping (URL) -> Void) {
            self.onOpenExternal = onOpenExternal
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if navigationAction.navigationType == .linkActivated {
                onOpenExternal(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}
