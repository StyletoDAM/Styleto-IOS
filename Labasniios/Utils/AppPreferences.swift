import Foundation

/// Gestionnaire centralisé des préférences de l'application
/// Sauvegarde l'état de connexion, l'utilisateur connecté et le thème
@MainActor
final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()
    
    // MARK: - Keys
    private let isLoggedInKey = "isLoggedIn"
    private let currentUserKey = "currentUser"
    private let themeModeKey = "selectedTheme"
    
    // MARK: - Published Properties
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    
    private init() {
        // Restaurer l'état au démarrage
        restoreState()
    }
    
    // MARK: - Login State Management
    
    /// Sauvegarde l'état de connexion et l'utilisateur
    func saveLoginState(user: User) {
        isLoggedIn = true
        currentUser = user  // Important : on met à jour la propriété publiée

        // Sauvegarde dans UserDefaults
        UserDefaults.standard.set(true, forKey: isLoggedInKey)
        
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: currentUserKey)
        }
        
        debugPrint("[AppPreferences] Utilisateur sauvegardé et publié : \(user.email) – Genre: \(user.gender.rawValue)")
        
        // FORCER LE RECHARGEMENT IMMÉDIAT (clé magique)
        NotificationCenter.default.post(name: .userDidUpdate, object: user)
    }
    
    /// Supprime l'état de connexion
    func clearLoginState() {
        isLoggedIn = false
        currentUser = nil
        
        // Supprimer de UserDefaults
        UserDefaults.standard.removeObject(forKey: isLoggedInKey)
        UserDefaults.standard.removeObject(forKey: currentUserKey)
        
        // 🔹 NOUVEAU : Notifier le CartManager du logout
            NotificationCenter.default.post(name: .didRequestNavigateToLogin, object: nil)
            
        debugPrint("[AppPreferences] Login state cleared")
    }
    
    /// Restaure l'état de connexion depuis UserDefaults
    private func restoreState() {
        // Restaurer l'état de connexion
        isLoggedIn = UserDefaults.standard.bool(forKey: isLoggedInKey)
        
        // Restaurer l'utilisateur
        if let userData = UserDefaults.standard.data(forKey: currentUserKey),
           var user = try? JSONDecoder().decode(User.self, from: userData) {
            
            if let balance = user.balance, balance > 1000 {
                // Si balance > 1000, c'est probablement en centimes, convertir en TND
                user.balance = balance / 100.0
                debugPrint("[AppPreferences] Migration: Balance convertie de \(balance) centimes à \(balance/100.0) TND")
                
                // Sauvegarder la version corrigée
                if let correctedData = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(correctedData, forKey: currentUserKey)
                }
            }
            
            currentUser = user
            debugPrint("[AppPreferences] User state restored: \(user.email) - Balance: \(user.balance ?? 0.0) TND")
            
            // ✅ CORRECTION : Récupérer le profil frais du serveur pour avoir la balance à jour
            if isLoggedIn {
                Task { @MainActor in
                    await refreshUserProfile()
                }
            }
        } else {
            currentUser = nil
        }
        
        debugPrint("[AppPreferences] State restored - isLoggedIn: \(isLoggedIn)")
    }
    
    /// Récupère le profil utilisateur frais du serveur
    @MainActor
    public func refreshUserProfile() async {
        guard let token = TokenManager.shared.getToken() else {
            debugPrint("[AppPreferences] No token available for profile refresh")
            return
        }
        
        do {
            let profileService = ProfileService()
            let freshUser = try await profileService.getProfile()
            
            // Mettre à jour avec les données fraîches du serveur
            self.currentUser = freshUser
            debugPrint("[AppPreferences] Profile refreshed - Balance: \(freshUser.balance ?? 0.0) TND")
            
            // Sauvegarder les nouvelles données
            if let userData = try? JSONEncoder().encode(freshUser) {
                UserDefaults.standard.set(userData, forKey: currentUserKey)
            }
            
            // Notifier les autres vues
            NotificationCenter.default.post(name: .userDidUpdate, object: freshUser)
        } catch {
            debugPrint("[AppPreferences] Failed to refresh profile: \(error)")
            // En cas d'erreur, on garde les données locales
        }
    }
    
    // MARK: - Theme Management
    
    /// Sauvegarde le mode de thème
    func saveThemeMode(_ mode: ThemeMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: themeModeKey)
        debugPrint("[AppPreferences] Theme mode saved: \(mode.rawValue)")
    }
    
    /// Récupère le mode de thème sauvegardé
    func getThemeMode() -> ThemeMode {
        if let themeString = UserDefaults.standard.string(forKey: themeModeKey),
           let mode = ThemeMode(rawValue: themeString) {
            return mode
        }
        return .system // Par défaut
    }
    
    // MARK: - Clear All
    
    /// Supprime toutes les préférences (pour le logout complet)
    func clearAll() {
        clearLoginState()
        // Note: On ne supprime pas le thème car c'est une préférence utilisateur
        debugPrint("[AppPreferences] All preferences cleared")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let didRequestNavigateToLogin = Notification.Name("didRequestNavigateToLogin")
    static let userDidUpdate = Notification.Name("userDidUpdate")
    static let favoritesDidChange = Notification.Name("favoritesDidChange") //  AJOUTER CETTE LIGNE
}


