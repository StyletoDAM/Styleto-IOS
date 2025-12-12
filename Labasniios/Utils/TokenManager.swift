import Foundation

final class TokenManager {
    static let shared = TokenManager()
    
    private let tokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId" // ✨ NOUVEAU : Comme Android
    
    private init() {}
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    // ✨ NOUVEAU : Gestion du refresh token
    func saveRefreshToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: refreshTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return UserDefaults.standard.string(forKey: refreshTokenKey)
    }
    
    // ✨ NOUVEAU : Gestion du userId (comme Android)
    func saveUserId(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: userIdKey)
        print("✅ [TokenManager] UserId sauvegardé: '\(userId)'")
    }
    
    func getUserId() -> String? {
        let userId = UserDefaults.standard.string(forKey: userIdKey)
        if let userId = userId {
            print("✅ [TokenManager] UserId récupéré: '\(userId)'")
        } else {
            print("⚠️ [TokenManager] Aucun userId trouvé")
        }
        return userId
    }
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey) // ✨ AJOUT
    }
}

