// Labasniios/LabasniiosApp.swift
// 📌 REMPLACER le fichier existant par celui-ci

import SwiftUI

@main
struct LabasniiosApp: App {
    
    @State private var showingSplash = true
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var appPreferences = AppPreferences.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        StripeConfig.shared.initialize()
        _ = ChatSocketManager.shared
        _ = NavigationTheme()
        
        // Forcer le bon thème dès le lancement de l'app
        DispatchQueue.main.async {
            ThemeManager.shared.updateThemeBasedOnUser()
        }
    }
    
    let persistenceController = CoreDataManager.shared
 
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Afficher la vue appropriée selon l'état de connexion
                if appPreferences.isLoggedIn, let user = appPreferences.currentUser {
                    MainTabView(user: user, onLogout: {
                        handleLogout()
                    })
                    .opacity(showingSplash ? 0 : 1)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                } else {
                    LabasniIntroView()
                        .opacity(showingSplash ? 0 : 1)
                }
 
                if showingSplash {
                    LaunchSplashView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Restaurer le thème sauvegardé
                let savedTheme = appPreferences.getThemeMode()
                themeManager.setThemeMode(savedTheme)
                themeManager.observeSystemTheme()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showingSplash = false
                    }
                }
            }
            // ✨ NOUVEAU: Gérer les Deep Links
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }
    
    private func handleLogout() {
        appPreferences.clearLoginState()
        TokenManager.shared.clearToken()
    }
    
    // MARK: - Deep Link Handler
    
    /// Gère les URLs de type labasni://subscriptions/success ou labasni://subscriptions/cancel
    private func handleDeepLink(_ url: URL) {
        print("🔗 [DeepLink] Received: \(url.absoluteString)")
        
        // Format attendu: labasni://subscriptions/success?session_id=xxx
        guard url.scheme == "labasni" else {
            print("⚠️ [DeepLink] Unknown scheme: \(url.scheme ?? "nil")")
            return
        }
        
        let path = url.path
        print("📍 [DeepLink] Path: \(path)")
        
        if path.contains("subscriptions/success") {
            handleSubscriptionSuccess(url: url)
        } else if path.contains("subscriptions/cancel") {
            handleSubscriptionCancel()
        }
    }
    
    private func handleSubscriptionSuccess(url: URL) {
        print("✅ [DeepLink] Subscription success!")
        
        // Extraire session_id si nécessaire
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let sessionId = components.queryItems?.first(where: { $0.name == "session_id" })?.value {
            print("   🆔 Session ID: \(sessionId)")
        }
        
        // Rafraîchir l'abonnement
        Task {
            await SubscriptionViewModel.shared.loadSubscriptionData()
        }
        
        // Afficher une notification de succès (optionnel)
        NotificationCenter.default.post(name: .subscriptionUpdated, object: nil)
    }
    
    private func handleSubscriptionCancel() {
        print("❌ [DeepLink] Subscription cancelled")
        // Optionnel: afficher un message à l'utilisateur
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let subscriptionUpdated = Notification.Name("subscriptionUpdated")
}
