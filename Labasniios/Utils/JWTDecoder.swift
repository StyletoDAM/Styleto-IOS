//
//  JWTDecoder.swift
//  Labasniios
//
//  Utilitaire pour décoder les tokens JWT
//
//  Ce fichier fournit des fonctions utilitaires pour décoder les tokens JWT
//  et extraire des informations, notamment l'ID utilisateur depuis le champ 'sub'.
//  Le décodage JWT est utilisé pour extraire automatiquement l'ID utilisateur
//  sans avoir besoin d'une requête API supplémentaire.
//
//  Architecture : Utilitaire statique
//  Dépendances : Foundation
//

import Foundation

/**
 * Utilitaire pour décoder les tokens JWT
 * 
 * Cette structure fournit des méthodes statiques pour :
 * - Décoder un token JWT et extraire le payload
 * - Extraire l'ID utilisateur depuis le champ 'sub' du JWT
 * - Normaliser les IDs pour les comparaisons
 * 
 * ⚠️ IMPORTANT : Le backend utilise le champ 'sub' pour stocker l'ID MongoDB
 * de l'utilisateur. C'est la source de vérité pour l'identification.
 */
struct JWTDecoder {
    /**
     * Décode un JWT et retourne le payload
     * 
     * Cette méthode décode la partie payload d'un token JWT (la partie centrale
     * entre les deux points). Le payload est décodé depuis Base64URL et parsé
     * comme JSON.
     * 
     * @param jwtToken Le token JWT complet (format: header.payload.signature)
     * @return Le payload décodé comme dictionnaire, ou nil en cas d'erreur
     */
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
