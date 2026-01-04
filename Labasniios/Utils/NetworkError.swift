//
//  NetworkError.swift
//  Labasniios
//
//  Gestion des erreurs réseau
//
//  Ce fichier définit les types d'erreurs réseau utilisés dans toute
//  l'application. Il fournit une représentation structurée des erreurs
//  pouvant survenir lors des communications avec le backend.
//
//  Architecture : Enum d'erreurs avec LocalizedError
//  Dépendances : Foundation
//

import Foundation

/**
 * Structure représentant une réponse d'erreur du serveur
 * 
 * Cette structure est utilisée pour décoder les réponses d'erreur
 * JSON du backend lorsqu'une requête échoue.
 * 
 * @property statusCode Code HTTP de l'erreur (optionnel)
 * @property message Message d'erreur descriptif
 * @property error Type d'erreur (optionnel)
 */
struct ErrorResponse: Decodable {
    let statusCode: Int?
    let message: String
    let error: String?
}

/**
 * Enumération des erreurs réseau possibles
 * 
 * Cette enum représente tous les types d'erreurs pouvant survenir
 * lors des communications réseau avec le backend. Elle implémente
 * LocalizedError pour fournir des messages d'erreur localisés
 * à l'utilisateur.
 * 
 * Cas d'erreur :
 * - invalidURL : URL malformée
 * - unauthorized : Token invalide ou expiré (401)
 * - requestFailed : Échec de la requête avec code HTTP
 * - decodingFailed : Erreur de décodage JSON
 * - noData : Aucune donnée reçue
 * - serverError : Erreur serveur (500+)
 * - serverMessage : Message d'erreur spécifique du serveur
 * - transport : Erreur de transport réseau (timeout, connexion, etc.)
 * - invalidData : Données reçues invalides
 */
enum NetworkError: LocalizedError {
    case invalidURL
    case unauthorized
    case requestFailed(Int)
    case decodingFailed
    case noData
    case serverError
    case serverMessage(String)   // ← garde ça, très utile
    case transport(Error)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide."
        case .unauthorized:
            return "Non autorisé. Veuillez vous reconnecter."
        case .requestFailed(let status):
            return "Échec de la requête (\(status))."
        case .decodingFailed:
            return "Erreur de décodage des données."
        case .noData:
            return "Aucune donnée reçue."
        case .serverError:
            return "Erreur du serveur."
        case .serverMessage(let message):
            return message
        case .transport(let error):
            return error.localizedDescription
        case .invalidData:
            return "Données invalides."
        }
    }
}
