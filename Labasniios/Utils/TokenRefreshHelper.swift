//
//  TokenRefreshHelper.swift
//  Labasniios
//
//  Helper pour le rafraîchissement automatique des tokens
//
//  Ce fichier fournit un helper pour rafraîchir automatiquement les tokens
//  d'authentification lorsqu'une requête API retourne une erreur 401 (Unauthorized).
//  Il évite les boucles infinies de rafraîchissement en gérant un état de
//  rafraîchissement en cours.
//
//  Architecture : Singleton pattern avec async/await
//  Dépendances : Foundation, AuthService
//

import Foundation

/**
 * Helper pour le rafraîchissement automatique des tokens
 * 
 * Cette classe implémente le pattern Singleton pour fournir un mécanisme
 * centralisé de rafraîchissement automatique des tokens. Elle est marquée
 * @MainActor pour garantir que toutes les opérations se déroulent sur le
 * thread principal.
 * 
 * Fonctionnalités :
 * - Détection automatique des erreurs 401
 * - Rafraîchissement du token via AuthService
 * - Réessai automatique de la requête originale avec le nouveau token
 * - Prévention des boucles infinies de rafraîchissement
 * - Gestion de la déconnexion si le refresh échoue
 * 
 * @see @MainActor pour l'exécution sur le thread principal
 * @see AuthService pour le rafraîchissement du token
 */
@MainActor
final class TokenRefreshHelper {
    static let shared = TokenRefreshHelper()
    private init() {}
    
    private var isRefreshing = false
    private var refreshTask: Task<(String, String), Error>?
    
    /// Effectue une requête avec refresh automatique en cas d'erreur 401
    func performRequestWithRefresh<T: Decodable>(
        request: URLRequest,
        decoder: JSONDecoder,
        responseType: T.Type
    ) async throws -> T {
        // Première tentative
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        // Si succès, retourner directement
        if (200..<300).contains(httpResponse.statusCode) {
            return try decoder.decode(T.self, from: data)
        }
        
        // Si 401, essayer de rafraîchir le token
        if httpResponse.statusCode == 401 {
            // Attendre que le refresh soit terminé (si en cours)
            if let task = refreshTask {
                let (newAccessToken, _) = try await task.value
                
                // Réessayer avec le nouveau token
                var newRequest = request
                newRequest.setValue("Bearer \(newAccessToken)", forHTTPHeaderField: "Authorization")
                let (retryData, retryResponse) = try await URLSession.shared.data(for: newRequest)
                
                guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                    throw NetworkError.noData
                }
                
                if (200..<300).contains(retryHttpResponse.statusCode) {
                    return try decoder.decode(T.self, from: retryData)
                } else {
                    throw NetworkError.requestFailed(retryHttpResponse.statusCode)
                }
            } else {
                // Lancer le refresh
                refreshTask = Task {
                    return try await AuthService.shared.refreshToken()
                }
                
                do {
                    let (newAccessToken, _) = try await refreshTask!.value
                    refreshTask = nil
                    
                    // Réessayer avec le nouveau token
                    var newRequest = request
                    newRequest.setValue("Bearer \(newAccessToken)", forHTTPHeaderField: "Authorization")
                    let (retryData, retryResponse) = try await URLSession.shared.data(for: newRequest)
                    
                    guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                        throw NetworkError.noData
                    }
                    
                    if (200..<300).contains(retryHttpResponse.statusCode) {
                        return try decoder.decode(T.self, from: retryData)
                    } else {
                        throw NetworkError.requestFailed(retryHttpResponse.statusCode)
                    }
                } catch {
                    refreshTask = nil
                    TokenManager.shared.clearToken()
                    throw NetworkError.serverMessage("Session expirée. Veuillez vous reconnecter.")
                }
            }
        }
        
        // Autre erreur, lancer normalement
        // Utiliser ErrorResponse existant de NetworkError.swift
        if let serverError = try? decoder.decode(ErrorResponse.self, from: data) {
            throw NetworkError.serverMessage(serverError.message)
        }
        throw NetworkError.requestFailed(httpResponse.statusCode)
    }
}

