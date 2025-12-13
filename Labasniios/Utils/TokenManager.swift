import Foundation

final class TokenManager {
    static let shared = TokenManager()
    
    private let tokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"
    
    private init() {}
    
    // MARK: - Token Management
    
    /// ✨ CRITIQUE : Sauvegarde le token et extrait automatiquement le userId du JWT
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        // ✨ CRITIQUE : Extraire et sauvegarder le userId du JWT automatiquement
        if let userId = JWTDecoder.extractUserId(from: token) {
            saveUserId(userId)
            print("✅ [TokenManager] Token et userId sauvegardés: '\(userId)'")
        } else {
            print("⚠️ [TokenManager] Impossible d'extraire userId du token")
        }
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
    
    // MARK: - User ID Management
    
    /// Sauvegarde l'ID utilisateur (appelé automatiquement par saveToken)
    private func saveUserId(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: userIdKey)
    }
    
    /// Récupère l'ID utilisateur stocké (provenant du JWT)
    /// ⚠️ IMPORTANT : Cet ID est extrait du champ 'sub' du JWT
    func getUserId() -> String? {
        let storedId = UserDefaults.standard.string(forKey: userIdKey)
        
        // Fallback : si pas stocké, essayer d'extraire du token actuel
        if storedId == nil, let token = getToken() {
            let extractedId = JWTDecoder.extractUserId(from: token)
            if let extractedId = extractedId {
                saveUserId(extractedId)
                print("✅ [TokenManager] UserId récupéré du token actuel: '\(extractedId)'")
            }
            return extractedId
        }
        
        return storedId
    }
    
    /// Récupère l'ID utilisateur de manière normalisée (trim + lowercase)
    /// ⚠️ UTILISER CETTE MÉTHODE POUR TOUTES LES COMPARAISONS
    func getNormalizedUserId() -> String? {
        guard let userId = getUserId() else { return nil }
        return userId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        print("🗑️ [TokenManager] Token et userId supprimés")
    }
    
    // MARK: - Debug Helper
    
    func printDebugInfo() {
        print("═══════════════════════════════════════")
        print("🔍 [TokenManager] Debug Info:")
        print("   - Token exists: \(getToken() != nil)")
        print("   - Stored User ID: '\(getUserId() ?? "nil")'")
        print("   - Normalized User ID: '\(getNormalizedUserId() ?? "nil")'")
        if let token = getToken(), let jwtUserId = JWTDecoder.extractUserId(from: token) {
            print("   - JWT User ID: '\(jwtUserId)'")
            print("   - IDs match: \(getUserId() == jwtUserId ? "✅" : "❌")")
        }
        print("═══════════════════════════════════════")
    }
}

