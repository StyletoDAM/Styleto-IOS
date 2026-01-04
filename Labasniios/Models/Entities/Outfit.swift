//
//  Outfit.swift
//  Labasniios
//
//  Modèle de données représentant une tenue (outfit)
//
//  Ce fichier définit la structure Outfit qui représente une tenue
//  dans l'application Labasni. Une tenue est une combinaison de vêtements
//  suggérée par l'IA ou créée par l'utilisateur.
//
//  Architecture : Modèle de données (Entity)
//  Dépendances : Foundation, CoreData, Codable
//

import Foundation
import CoreData

/**
 * Structure représentant une tenue (outfit)
 * 
 * Une tenue est une combinaison de plusieurs vêtements suggérée par l'IA
 * ou créée manuellement par l'utilisateur. Elle peut être associée à un
 * type d'événement et un type de météo pour une meilleure personnalisation.
 * 
 * @property id Identifiant unique de la tenue
 * @property clothesIds Liste des vêtements composant la tenue
 * @property eventType Type d'événement (ex: "casual", "formal", "party")
 * @property weatherType Type de météo (ex: "sunny", "rainy", "cold")
 * @property status Statut de la tenue (ex: "pending", "approved", "rejected")
 * @property createdAt Date de création de la tenue
 * @property updatedAt Date de dernière mise à jour
 */
struct Outfit: Identifiable, Codable {
    let id: String
    let clothesIds: [Clothe]
    let eventType: String?
    let weatherType: String?
    var status: String
    let createdAt: Date
    let updatedAt: Date

    // userId peut être String OU ClotheUserInfo
    private let userIdString: String?
    private let userIdObject: ClotheUserInfo?

    // Accès public
    var userIdAsString: String? { userIdString }
    var userIdAsUser: ClotheUserInfo? { userIdObject }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, clothesIds, eventType, weatherType, status, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        clothesIds = try container.decode([Clothe].self, forKey: .clothesIds)
        eventType = try container.decodeIfPresent(String.self, forKey: .eventType)
        weatherType = try container.decodeIfPresent(String.self, forKey: .weatherType)
        status = try container.decode(String.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // userId peut être String ou ClotheUserInfo
        if let string = try? container.decode(String.self, forKey: .userId) {
            userIdString = string
            userIdObject = nil
        } else if let user = try? container.decode(ClotheUserInfo.self, forKey: .userId) {
            userIdString = nil
            userIdObject = user
        } else {
            userIdString = nil
            userIdObject = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(clothesIds, forKey: .clothesIds)
        try container.encodeIfPresent(eventType, forKey: .eventType)
        try container.encodeIfPresent(weatherType, forKey: .weatherType)
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        if let string = userIdString {
            try container.encode(string, forKey: .userId)
        } else if let user = userIdObject {
            try container.encode(user, forKey: .userId)
        }
    }

    var title: String { eventType ?? "Outfit" }
    var dateLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    var isFavorite: Bool { isLocallyFavorite }
    var itemsCount: Int { clothesIds.count }
    var previewClothes: [Clothe] { Array(clothesIds.prefix(3)) }
}

// MARK: - Local Favorites (CoreData)
extension Outfit {
    var isLocallyFavorite: Bool {
        return FavoritesManager.shared.isFavorite(outfitId: id)
    }
}
