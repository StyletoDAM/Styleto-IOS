//
//  CartAPIService.swift
//  Labasniios
//
//  Service API pour la gestion du panier via le backend
//
//  Ce fichier gère toutes les opérations API liées au panier d'achat :
//  - Récupération du panier depuis le serveur
//  - Ajout et suppression d'articles
//  - Vidage du panier
//  - Vérification du statut des articles (disponible/vendu)
//
//  Architecture : Singleton pattern avec méthodes async/await
//  Dépendances : Foundation, URLSession
//

import Foundation
import Combine

/**
 * Service API pour la gestion du panier via le backend
 * 
 * Cette classe implémente le pattern Singleton pour fournir un accès
 * global aux opérations API du panier. Elle utilise async/await pour
 * les opérations asynchrones et gère l'authentification automatique
 * via TokenManager.
 * 
 * Le panier est géré côté serveur pour garantir la cohérence entre
 * les appareils et permettre la synchronisation en temps réel.
 */
final class CartAPIService {
    static let shared = CartAPIService()
    
    private let baseURL = APIConstants.baseURL
    private let tokenManager = TokenManager.shared
    
    private init() {}
    
    // MARK: - Get Cart
    func getCart() async throws -> CartResponse {
        guard let url = URL(string: "/cart", relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverMessage(errorResponse.message)
            }
            throw NetworkError.serverError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(CartResponse.self, from: data)
    }
    
    // MARK: - Add to Cart
    func addToCart(storeItemId: String) async throws -> CartResponse {
        guard let url = URL(string: "/cart/add", relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["storeItemId": storeItemId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverMessage(errorResponse.message)
            }
            throw NetworkError.serverError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(CartResponse.self, from: data)
    }
    
    // MARK: - Remove from Cart
    func removeFromCart(storeItemId: String) async throws -> CartResponse {
        guard let url = URL(string: "/cart/remove", relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["storeItemId": storeItemId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverMessage(errorResponse.message)
            }
            throw NetworkError.serverError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(CartResponse.self, from: data)
    }
    
    // MARK: - Clear Cart
    func clearCart() async throws {
        guard let url = URL(string: "/cart/clear", relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }
    }
}

// MARK: - Response Models
struct CartResponse: Codable {
    let id: String
    let userId: String
    let items: [CartItemResponse]
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case items
        case createdAt
        case updatedAt
    }
}

struct CartItemResponse: Codable {
    let storeItemId: String
    let addedAt: Date
    let storeItem: StoreItemInCartResponse?
    
    enum CodingKeys: String, CodingKey {
        case storeItemId
        case addedAt
        case storeItem
    }
}

struct StoreItemInCartResponse: Codable {
    let id: String
    let price: Double
    let size: String
    let status: String // "available" | "sold"
    let clothesId: ClothesInCartResponse?
    let userId: UserInCartResponse? // ✨ Peut être nil, string, ou objet
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case price
        case size
        case status
        case clothesId
        case userId
    }
    
    // ✨ NOUVEAU : Décodage personnalisé pour gérer userId et clothesId comme string ou objet
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        price = try container.decode(Double.self, forKey: .price)
        size = try container.decode(String.self, forKey: .size)
        status = try container.decode(String.self, forKey: .status)
        
        // clothesId peut être nil, string, ou objet
        if container.contains(.clothesId) {
            if let clothesIdString = try? container.decode(String.self, forKey: .clothesId) {
                // C'est un string (ObjectId)
                clothesId = ClothesInCartResponse(id: clothesIdString, imageURL: nil, category: nil, style: nil, color: nil)
            } else {
                // Essayer de décoder comme objet
                clothesId = try? container.decode(ClothesInCartResponse.self, forKey: .clothesId)
            }
        } else {
            clothesId = nil
        }
        
        // ✨ userId peut être nil, string, ou objet
        if container.contains(.userId) {
            if let userIdString = try? container.decode(String.self, forKey: .userId) {
                // C'est un string (ObjectId)
                userId = UserInCartResponse(id: userIdString, fullName: nil, profilePicture: nil)
            } else {
                // Essayer de décoder comme objet
                userId = try? container.decode(UserInCartResponse.self, forKey: .userId)
            }
        } else {
            userId = nil
        }
    }
}

struct ClothesInCartResponse: Codable {
    let id: String
    let imageURL: String?
    let category: String?
    let style: String?
    let color: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case imageURL
        case category
        case style
        case color
    }
    
    // ✨ NOUVEAU : Décodage personnalisé pour gérer string ou objet
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // _id peut être directement dans le container ou dans un sous-objet
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idString = try? container.decode(String.self, forKey: CodingKeys(stringValue: "_id")!) {
            id = idString
        } else {
            // Si c'est un string simple (ObjectId), essayer de décoder comme string
            let singleValueContainer = try decoder.singleValueContainer()
            if let idString = try? singleValueContainer.decode(String.self) {
                id = idString
                imageURL = nil
                category = nil
                style = nil
                color = nil
                return
            }
            throw DecodingError.keyNotFound(CodingKeys.id, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not decode _id"))
        }
        
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        style = try container.decodeIfPresent(String.self, forKey: .style)
        color = try container.decodeIfPresent(String.self, forKey: .color)
    }
    
    // ✨ NOUVEAU : Initializer pour créer depuis un string (ObjectId)
    init(id: String, imageURL: String?, category: String?, style: String?, color: String?) {
        self.id = id
        self.imageURL = imageURL
        self.category = category
        self.style = style
        self.color = color
    }
}

struct UserInCartResponse: Codable {
    let id: String
    let fullName: String?
    let profilePicture: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fullName
        case profilePicture
    }
    
    // ✨ NOUVEAU : Décodage personnalisé pour gérer string ou objet
    init(from decoder: Decoder) throws {
        // Si c'est un string simple (ObjectId), essayer de décoder comme string
        if let singleValueContainer = try? decoder.singleValueContainer() {
            if let idString = try? singleValueContainer.decode(String.self) {
                id = idString
                fullName = nil
                profilePicture = nil
                return
            }
        }
        
        // Sinon, décoder comme objet
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ✨ MODIFIÉ : _id devrait maintenant être présent (backend modifié)
        // Mais on garde un fallback au cas où
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else {
            // Si _id n'est pas présent, utiliser une valeur par défaut
            id = "unknown"
        }
        
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        profilePicture = try container.decodeIfPresent(String.self, forKey: .profilePicture)
    }
    
    // ✨ NOUVEAU : Initializer pour créer depuis un string (ObjectId)
    init(id: String, fullName: String?, profilePicture: String?) {
        self.id = id
        self.fullName = fullName
        self.profilePicture = profilePicture
    }
}

