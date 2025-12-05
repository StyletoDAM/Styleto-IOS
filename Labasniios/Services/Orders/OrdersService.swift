// Services/Orders/OrdersService.swift
import Foundation

// MARK: - Order Models

struct OrderClothInfo: Codable, Equatable {
    let id: String
    let name: String?
    let category: String?
    let type: String?
    let imageURL: String?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case category
        case type
        case imageURL
        case imageUrl
    }
    
    init(id: String, name: String?, category: String?, type: String?, imageURL: String?, imageUrl: String?) {
        self.id = id
        self.name = name
        self.category = category
        self.type = type
        self.imageURL = imageURL
        self.imageUrl = imageUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Gérer _id ou id
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else if let idKey = CodingKeys(stringValue: "_id"), let idValue = try? container.decode(String.self, forKey: idKey) {
            id = idValue
        } else {
            // Si ni _id ni id ne sont présents, utiliser une chaîne vide
            print("⚠️ [OrderClothInfo] _id missing, using empty string")
            id = ""
        }
        
        name = try container.decodeIfPresent(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
    }
    
    var displayImageUrl: String? {
        imageURL ?? imageUrl
    }
    
    var displayType: String? {
        category ?? type
    }
}

struct OrderUserInfo: Codable, Equatable {
    let id: String
    let fullName: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fullName
        case email
    }
    
    init(id: String, fullName: String?, email: String?) {
        self.id = id
        self.fullName = fullName
        self.email = email
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Gérer _id ou id
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else if let idKey = CodingKeys(stringValue: "_id"), let idValue = try? container.decode(String.self, forKey: idKey) {
            id = idValue
        } else {
            // Si ni _id ni id ne sont présents, utiliser une chaîne vide
            print("⚠️ [OrderUserInfo] _id missing, using empty string")
            id = ""
        }
        
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
    }
}

struct OrderResponse: Codable {
    let id: String
    let clothesId: OrderClothInfo
    let userId: OrderUserInfo
    let price: Double
    let orderDate: Date
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case clothesId
        case userId
        case price
        case orderDate
        case createdAt
        case updatedAt
    }
    
    // Custom init pour gérer clothesId et userId (peuvent être String ou Object)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Décode id (peut être _id ou id)
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else if let idKey = CodingKeys(stringValue: "_id"), let idValue = try? container.decode(String.self, forKey: idKey) {
            id = idValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.id, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "id or _id is missing"
            ))
        }
        
        // Décode price
        price = try container.decode(Double.self, forKey: .price)
        
        // Décode orderDate comme Date (obligatoire)
        if let date = try? container.decode(Date.self, forKey: .orderDate) {
            orderDate = date
        } else if let dateString = try? container.decode(String.self, forKey: .orderDate) {
            // Fallback: si c'est une string, essayer de la parser
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                orderDate = date
            } else {
                // Essayer sans fractions de secondes
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    orderDate = date
                } else {
                    // Dernier fallback: date actuelle
                    print("⚠️ [OrderResponse] Could not parse orderDate: \(dateString), using current date")
                    orderDate = Date()
                }
            }
        } else {
            // Si orderDate est manquant, utiliser la date actuelle
            print("⚠️ [OrderResponse] orderDate is missing, using current date")
            orderDate = Date()
        }
        
        // Décode createdAt et updatedAt comme Date (optionnels)
        if let date = try? container.decodeIfPresent(Date.self, forKey: .createdAt) {
            createdAt = date
        } else if let dateString = try? container.decodeIfPresent(String.self, forKey: .createdAt), !dateString.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                createdAt = formatter.date(from: dateString)
            }
        } else {
            createdAt = nil
        }
        
        if let date = try? container.decodeIfPresent(Date.self, forKey: .updatedAt) {
            updatedAt = date
        } else if let dateString = try? container.decodeIfPresent(String.self, forKey: .updatedAt), !dateString.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                updatedAt = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                updatedAt = formatter.date(from: dateString)
            }
        } else {
            updatedAt = nil
        }
        
        // clothesId peut être String ou OrderClothInfo (objet avec _id, name, category, imageURL)
        if let clothInfo = try? container.decode(OrderClothInfo.self, forKey: .clothesId) {
            clothesId = clothInfo
        } else if let clothIdString = try? container.decode(String.self, forKey: .clothesId) {
            // Si c'est juste un ID string, créer un OrderClothInfo minimal
            clothesId = OrderClothInfo(
                id: clothIdString,
                name: nil,
                category: nil,
                type: nil,
                imageURL: nil,
                imageUrl: nil
            )
        } else {
            // Si clothesId est manquant, créer un OrderClothInfo vide
            print("⚠️ [OrderResponse] clothesId is missing, creating empty OrderClothInfo")
            clothesId = OrderClothInfo(
                id: "",
                name: nil,
                category: nil,
                type: nil,
                imageURL: nil,
                imageUrl: nil
            )
        }
        
        // userId peut être String ou OrderUserInfo (objet avec _id, fullName, email)
        if let userInfo = try? container.decode(OrderUserInfo.self, forKey: .userId) {
            userId = userInfo
        } else if let userIdString = try? container.decode(String.self, forKey: .userId) {
            // Si c'est juste un ID string, créer un OrderUserInfo minimal
            userId = OrderUserInfo(
                id: userIdString,
                fullName: nil,
                email: nil
            )
        } else {
            // Si userId est manquant, créer un OrderUserInfo vide
            print("⚠️ [OrderResponse] userId is missing, creating empty OrderUserInfo")
            userId = OrderUserInfo(
                id: "",
                fullName: nil,
                email: nil
            )
        }
    }
}

struct CreateOrderRequest: Codable {
    let clothesId: String
    let price: Double
}

// MARK: - Transaction Models
struct TransactionResponse: Codable, Identifiable {
    let id: String
    let type: String // "incoming" ou "outgoing"
    let amount: Double
    let description: String
    let date: Date
    let paymentMethod: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type
        case amount
        case description
        case date
        case paymentMethod
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Décode id
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else {
            id = ""
        }
        
        type = try container.decode(String.self, forKey: .type)
        amount = try container.decode(Double.self, forKey: .amount)
        description = try container.decode(String.self, forKey: .description)
        paymentMethod = try container.decodeIfPresent(String.self, forKey: .paymentMethod)
        
        // Décode date
        if let dateValue = try? container.decode(Date.self, forKey: .date) {
            date = dateValue
        } else if let dateString = try? container.decode(String.self, forKey: .date) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsedDate = formatter.date(from: dateString) {
                date = parsedDate
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                date = formatter.date(from: dateString) ?? Date()
            }
        } else {
            date = Date()
        }
        
        // Décode createdAt
        if let createdAtValue = try? container.decodeIfPresent(Date.self, forKey: .createdAt) {
            createdAt = createdAtValue
        } else if let createdAtString = try? container.decodeIfPresent(String.self, forKey: .createdAt), !createdAtString.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsedDate = formatter.date(from: createdAtString) {
                createdAt = parsedDate
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                createdAt = formatter.date(from: createdAtString)
            }
        } else {
            createdAt = nil
        }
    }
}

class OrdersService {
    static let shared = OrdersService()
    private init() {}
    
    func getMyOrders() async throws -> [OrderResponse] {
        guard let url = URL(string: APIConstants.baseURL.absoluteString + "/orders") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug: Log response
        if let http = response as? HTTPURLResponse {
            print("🔍 [OrdersService] Status Code: \(http.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 [OrdersService] Response: \(jsonString)")
            }
        }
        
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                throw NetworkError.serverMessage(message)
            }
            throw NetworkError.requestFailed(http.statusCode)
        }
        
        // Utiliser un JSONDecoder avec dateDecodingStrategy personnalisé
        let decoder = JSONDecoder()
        
        // Stratégie de décodage de date avec support des fractions de secondes
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Créer le formatter à l'intérieur de la closure pour éviter les problèmes de capture
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback sans fractions de secondes
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected ISO8601 date string, but got \(dateString)"
            )
        }
        
        do {
            let orders = try decoder.decode([OrderResponse].self, from: data)
            print("✅ [OrdersService] Decoded \(orders.count) orders successfully")
            return orders
        } catch {
            print("❌ [OrdersService] Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("Type mismatch: \(type) at \(context.codingPath.map { $0.stringValue })")
                case .keyNotFound(let key, let context):
                    print("Key not found: \(key.stringValue) at \(context.codingPath.map { $0.stringValue })")
                case .valueNotFound(let type, let context):
                    print("Value not found: \(type) at \(context.codingPath.map { $0.stringValue })")
                case .dataCorrupted(let context):
                    print("Data corrupted at \(context.codingPath.map { $0.stringValue }): \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
            throw error
        }
    }
    
    func createOrder(clothesId: String, price: Double) async throws -> OrderResponse {
        guard let url = URL(string: APIConstants.baseURL.absoluteString + "/orders") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = CreateOrderRequest(clothesId: clothesId, price: price)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                throw NetworkError.serverMessage(message)
            }
            throw NetworkError.requestFailed(http.statusCode)
        }
        
        // Utiliser un JSONDecoder avec dateDecodingStrategy
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let order = try decoder.decode(OrderResponse.self, from: data)
            print("✅ [OrdersService] Order created successfully")
            return order
        } catch {
            print("❌ [OrdersService] Order decoding error: \(error)")
            throw error
        }
    }
    
    func getMyTransactions() async throws -> [TransactionResponse] {
        guard let url = URL(string: APIConstants.baseURL.absoluteString + "/orders/transactions") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let http = response as? HTTPURLResponse {
            print("🔍 [OrdersService] Transactions Status Code: \(http.statusCode)")
        }
        
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                throw NetworkError.serverMessage(message)
            }
            throw NetworkError.requestFailed(http.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected ISO8601 date string, but got \(dateString)"
            )
        }
        
        do {
            let transactions = try decoder.decode([TransactionResponse].self, from: data)
            print("✅ [OrdersService] Decoded \(transactions.count) transactions successfully")
            return transactions
        } catch {
            print("❌ [OrdersService] Transactions decoding error: \(error)")
            throw error
        }
    }
}

