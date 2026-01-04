//
//  JSONDecoder+ISO8601.swift
//  Labasniios
//
//  Extension JSONDecoder pour le décodage des dates ISO8601
//
//  Ce fichier fournit une extension pratique pour JSONDecoder qui
//  configure automatiquement le décodage des dates au format ISO8601.
//  Cela garantit une gestion cohérente des dates dans toute l'application.
//
//  Architecture : Extension utilitaire
//  Dépendances : Foundation
//

import Foundation

/**
 * Extension JSONDecoder pour le décodage des dates ISO8601
 * 
 * Cette extension fournit un JSONDecoder préconfiguré avec la stratégie
 * de décodage des dates ISO8601. Utilisez cette instance pour décoder
 * toutes les réponses JSON contenant des dates depuis le backend.
 * 
 * Exemple d'utilisation :
 * ```swift
 * let decoder = JSONDecoder.iso8601
 * let user = try decoder.decode(User.self, from: data)
 * ```
 */
extension JSONDecoder {
    /**
     * Instance JSONDecoder préconfigurée pour les dates ISO8601
     * 
     * Cette propriété statique retourne un JSONDecoder configuré avec
     * la stratégie de décodage des dates ISO8601, qui est le format
     * standard utilisé par le backend Labasni.
     */
    static let iso8601: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
