import SwiftUI

@main
struct LabasniiosApp: App {
    @State private var showingSplash = true
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var appPreferences = AppPreferences.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // ✅ AJOUTER CETTE LIGNE
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
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)  // ✅ AJOUTER ÇA
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
        }
    }
    
    private func handleLogout() {
        appPreferences.clearLoginState()
        TokenManager.shared.clearToken()
    }
}
