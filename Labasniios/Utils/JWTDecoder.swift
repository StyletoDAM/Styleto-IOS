import Foundation

struct JWTDecoder {
    /// Décode un JWT et retourne le payload
    static func decode(jwtToken: String) -> [String: Any]? {
        let parts = jwtToken.split(separator: ".")
        guard parts.count > 1 else { 
            print("❌ [JWTDecoder] Token invalide (pas assez de parties)")
            return nil 
        }
        
        var payload = String(parts[1])
        payload = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let padding = payload.count % 4
        if padding != 0 {
            payload += String(repeating: "=", count: 4 - padding)
        }
        
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ [JWTDecoder] Impossible de décoder le payload")
            return nil
        }
        
        return json
    }
    
    /// Extrait l'ID utilisateur du JWT
    /// ⚠️ CRITIQUE : Le backend utilise 'sub' comme ID utilisateur principal
    /// Le champ 'sub' contient l'ID MongoDB (_id) de l'utilisateur
    static func extractUserId(from token: String) -> String? {
        guard !token.isEmpty else {
            print("⚠️ [JWTDecoder] Token vide")
            return nil
        }
        
        guard let payload = decode(jwtToken: token) else { 
            print("⚠️ [JWTDecoder] Impossible de décoder le token")
            return nil 
        }
        
        // ✨ CRITIQUE : Le backend (auth.service.ts) utilise 'sub' comme ID principal
        // Voir: const payload = { email: user.email, sub: user._id.toString() }
        // Priorité absolue : sub (c'est l'ID MongoDB)
        let userId = payload["sub"] as? String
        
        if let userId = userId {
            print("✅ [JWTDecoder] User ID extrait du JWT (sub): '\(userId)'")
            print("   Clés disponibles dans le JWT: \(payload.keys.joined(separator: ", "))")
            return userId
        } else {
            print("⚠️ [JWTDecoder] Aucun 'sub' trouvé dans le JWT")
            print("   Clés disponibles: \(payload.keys.joined(separator: ", "))")
            print("   Payload complet: \(payload)")
            return nil
        }
    }
    
    /// Normalise un ID pour la comparaison (trim + lowercase)
    static func normalizeId(_ id: String?) -> String {
        guard let id = id, !id.isEmpty else { return "" }
        return id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
