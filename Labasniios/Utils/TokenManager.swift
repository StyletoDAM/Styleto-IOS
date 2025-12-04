import Foundation

final class TokenManager {
    static let shared = TokenManager()
    
    private let tokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken" // ✨ NOUVEAU
    
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
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey) // ✨ AJOUT
    }
}

