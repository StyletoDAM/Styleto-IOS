//
//  Store.swift
//  Labasniios
//
//  Modèle de données représentant un article du store (marketplace)
//
//  Ce fichier définit la structure Store qui représente un article
//  mis en vente dans le marketplace de l'application Labasni.
//  Un article peut être un vêtement avec un prix, une taille, et un état.
//
//  Architecture : Modèle de données (Entity)
//  Dépendances : Foundation, SwiftUI, Codable
//

import Foundation
import SwiftUI

/**
 * Structure représentant un article du store (marketplace)
 * 
 * Cette structure représente un article mis en vente dans le marketplace.
 * Elle contient toutes les informations nécessaires pour la vente :
 * - Le vêtement associé
 * - Le prix et la taille
 * - L'état du produit (neuf, usé, endommagé)
 * - Le statut de vente (disponible, vendu)
 * - Les informations de paiement Stripe
 * 
 * @property id Identifiant unique de l'article
 * @property userId Identifiant du vendeur
 * @property clothesId Identifiant du vêtement mis en vente
 * @property price Prix de vente en dinars tunisiens
 * @property size Taille du vêtement (optionnel)
 * @property status Statut de vente (available, sold)
 * @property createdAt Date de création de l'annonce
 * @property updatedAt Date de dernière mise à jour
 * @property buyerId Identifiant de l'acheteur (si vendu)
 * @property soldAt Date de vente (si vendu)
 * @property stripePaymentIntentId ID de l'intention de paiement Stripe
 * @property condition État du produit (new, used, damaged)
 * @property clothe Objet vêtement complet (si fourni par le serveur)
 * @property user Objet utilisateur complet (si fourni par le serveur)
 */
struct Store: Codable, Identifiable, Equatable { 
    let id: String
    let userId: String
    let clothesId: String?
    let price: Double
    let size: String?
    let status: StoreStatus
    let createdAt: Date?
    let updatedAt: Date?
    
    let buyerId: String?
    let soldAt: Date?
    let stripePaymentIntentId: String?
    let condition: ProductCondition?
    
    let clothe: Clothe?
    let user: User?
    
    enum StoreStatus: String, Codable {
        case available
        case sold
    }
    
    enum ProductCondition: String, Codable {
        case new = "new"
        case used = "used"
        case damaged = "damaged"
        
        var displayName: String {
            switch self {
            case .new: return "New"
            case .used: return "Used"
            case .damaged: return "Damaged"
            }
        }
        
        var color: Color {
            switch self {
            case .new: return .green
            case .used: return .orange
            case .damaged: return .red
            }
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let value = try container.decodeIfPresent(String.self, forKey: .id) {
            id = value
        } else if let value = try container.decodeIfPresent(String.self, forKey: .mongoId) {
            id = value
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.id,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing identifier in store payload"
                )
            )
        }
        
        if let userIdString = try? container.decode(String.self, forKey: .userId) {
            userId = userIdString
            user = nil
        } else if let userObject = try? container.decode(User.self, forKey: .userId) {
            userId = userObject.id
            user = userObject
        } else {
            userId = ""
            user = nil
        }
        
        if let clothesIdString = try? container.decode(String.self, forKey: .clothesId) {
            clothesId = clothesIdString
            clothe = nil
        } else if let clotheObject = try? container.decode(Clothe.self, forKey: .clothesId) {
            clothesId = clotheObject.id
            clothe = clotheObject
        } else {
            clothesId = nil
            clothe = nil
        }
        
        price = try container.decode(Double.self, forKey: .price)
        size = try container.decodeIfPresent(String.self, forKey: .size)
        status = try container.decode(StoreStatus.self, forKey: .status)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        
        buyerId = try container.decodeIfPresent(String.self, forKey: .buyerId)
        soldAt = try container.decodeIfPresent(Date.self, forKey: .soldAt)
        stripePaymentIntentId = try container.decodeIfPresent(String.self, forKey: .stripePaymentIntentId)
        condition = try container.decodeIfPresent(ProductCondition.self, forKey: .condition)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(clothesId, forKey: .clothesId)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(buyerId, forKey: .buyerId)
        try container.encodeIfPresent(soldAt, forKey: .soldAt)
        try container.encodeIfPresent(stripePaymentIntentId, forKey: .stripePaymentIntentId)
        try container.encodeIfPresent(condition, forKey: .condition)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case userId
        case clothesId
        case price
        case size
        case status
        case createdAt
        case updatedAt
        case buyerId
        case soldAt
        case stripePaymentIntentId
        case condition
    }
    
    // ✅ NOUVEAU : Conformité Equatable
    static func == (lhs: Store, rhs: Store) -> Bool {
        lhs.id == rhs.id
    }
}

extension Store {
    var isAvailable: Bool {
        status == .available
    }
    
    var isSold: Bool {
        status == .sold
    }
}
