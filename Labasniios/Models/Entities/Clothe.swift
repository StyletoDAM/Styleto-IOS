//
//  Clothe.swift
//  Labasniios
//
//  Modèle de données représentant un vêtement
//
//  Ce fichier définit la structure Clothe qui représente un vêtement
//  dans l'application Labasni. Il contient toutes les informations
//  nécessaires pour gérer les vêtements scannés et analysés par l'IA.
//
//  Architecture : Modèle de données (Entity)
//  Dépendances : Foundation, Codable
//

import Foundation

// MARK: - ClotheUserInfo

/**
 * Structure représentant les informations utilisateur associées à un vêtement
 * 
 * Cette structure est utilisée lorsque le serveur renvoie un objet utilisateur
 * complet au lieu d'un simple ID. Elle contient toutes les informations
 * de profil de l'utilisateur propriétaire du vêtement.
 */
struct ClotheUserInfo: Codable {
    let id: String
    let fullName: String?
    let email: String?
    let gender: String?
    let preferences: [String]?
    let phoneNumber: String?
    let authProvider: String?
    let isVerified: Bool?
    let createdAt: Date?
    let updatedAt: Date?
    let googleId: String?
    let profilePicture: String?

    enum CodingKeys: String, CodingKey {
        case id, fullName, email, gender, preferences, phoneNumber
        case authProvider, isVerified, createdAt, updatedAt, googleId, profilePicture
    }
}

// MARK: - Clothe
struct Clothe: Identifiable, Codable {
    let id: String
    let imageURL: String
    let processedImageURL: String?  // ✅ AJOUT CRUCIAL
    let category: String?
    let season: String?
    let color: String?
    let style: String?
    let acceptedCount: Int?
    let rejectedCount: Int?

    // userId peut être String OU ClotheUserInfo
    private let userIdString: String?
    private let userIdObject: ClotheUserInfo?

    // Accès public
    var userIdAsString: String? { userIdString }
    var userIdAsUser: ClotheUserInfo? { userIdObject }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case imageURL
        case processedImageURL  // ✅ AJOUT
        case category, season, color, style, userId, acceptedCount, rejectedCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        processedImageURL = try container.decodeIfPresent(String.self, forKey: .processedImageURL)  // ✅ AJOUT
        category = try container.decodeIfPresent(String.self, forKey: .category)
        season = try container.decodeIfPresent(String.self, forKey: .season)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        style = try container.decodeIfPresent(String.self, forKey: .style)
        
        acceptedCount = try container.decodeIfPresent(Int.self, forKey: .acceptedCount)
        rejectedCount = try container.decodeIfPresent(Int.self, forKey: .rejectedCount)

        if let string = try? container.decode(String.self, forKey: .userId) {
            userIdString = string
            userIdObject = nil
        }
        else if let user = try? container.decode(ClotheUserInfo.self, forKey: .userId) {
            userIdString = nil
            userIdObject = user
        }
        else {
            userIdString = nil
            userIdObject = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(processedImageURL, forKey: .processedImageURL)  // ✅ AJOUT
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(season, forKey: .season)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encodeIfPresent(style, forKey: .style)
        try container.encodeIfPresent(acceptedCount, forKey: .acceptedCount)
        try container.encodeIfPresent(rejectedCount, forKey: .rejectedCount)

        if let string = userIdString {
            try container.encode(string, forKey: .userId)
        } else if let user = userIdObject {
            try container.encode(user, forKey: .userId)
        }
    }
}
