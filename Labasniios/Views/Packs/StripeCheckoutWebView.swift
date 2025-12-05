// Labasniios/Views/Packs/StripeCheckoutWebView.swift
// 📌 NOUVEAU FICHIER - Créer ce fichier dans Xcode

import SwiftUI
import WebKit

/// Vue WebView pour afficher Stripe Checkout
struct StripeCheckoutWebView: UIViewRepresentable {
    let url: URL
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: StripeCheckoutWebView
        
        init(_ parent: StripeCheckoutWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            let urlString = url.absoluteString
            print("🌐 [CheckoutWebView] Navigation: \(urlString)")
            
            // Détecter la redirection success
            if urlString.contains("/subscriptions/success") {
                print("✅ [CheckoutWebView] Success detected!")
                decisionHandler(.cancel)
                
                // Extraire le session_id
                if let sessionId = extractSessionId(from: url) {
                    print("   🆔 Session ID: \(sessionId)")
                }
                
                parent.onSuccess()
                return
            }
            
            // Détecter la redirection cancel
            if urlString.contains("/subscriptions/cancel") {
                print("❌ [CheckoutWebView] Cancel detected!")
                decisionHandler(.cancel)
                parent.onCancel()
                return
            }
            
            decisionHandler(.allow)
        }
        
        private func extractSessionId(from url: URL) -> String? {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                return nil
            }
            
            return queryItems.first(where: { $0.name == "session_id" })?.value
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🔄 [CheckoutWebView] Loading started")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ [CheckoutWebView] Loading finished")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ [CheckoutWebView] Loading failed: \(error.localizedDescription)")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        // Permettre les cookies
        webView.configuration.websiteDataStore = .default()
        
        // Charger l'URL
        let request = URLRequest(url: url)
        webView.load(request)
        
        print("🌐 [CheckoutWebView] Loading URL: \(url.absoluteString)")
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Pas besoin de mise à jour
    }
}

// MARK: - Sheet Wrapper

struct StripeCheckoutSheet: View {
    let checkoutUrl: String
    let onSuccess: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if let url = URL(string: checkoutUrl) {
                    StripeCheckoutWebView(
                        url: url,
                        onSuccess: {
                            dismiss()
                            onSuccess()
                        },
                        onCancel: {
                            dismiss()
                            onCancel()
                        }
                    )
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("Invalid checkout URL")
                            .font(.headline)
                            .padding()
                    }
                }
            }
            .navigationTitle("Complete Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        onCancel()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}
