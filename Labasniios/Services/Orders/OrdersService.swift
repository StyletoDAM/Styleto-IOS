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
        
        // PROTECTION CRITIQUE : Vérifier d'abord le type avant de décoder
        // Si le type n'existe pas ou n'est pas "incoming"/"outgoing", c'est probablement un order
        guard let typeString = try? container.decode(String.self, forKey: .type) else {
            throw DecodingError.keyNotFound(
                CodingKeys.type,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Missing 'type' field - this might be an Order, not a Transaction"
                )
            )
        }
        
        // Le type doit être "incoming" ou "outgoing"
        guard typeString == "incoming" || typeString == "outgoing" else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid transaction type: '\(typeString)'. Must be 'incoming' or 'outgoing'. This might be an Order."
                )
            )
        }
        type = typeString
        
        // Décode id
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else {
            id = ""
        }
        
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

// MARK: - Unified History Model
struct HistoryItemResponse: Codable, Identifiable {
    let id: String
    let type: String // "Purchased" ou "Sold"
    let clothesId: OrderClothInfo
    let price: Double
    let date: Date
    let createdAt: Date?
    let size: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type
        case clothesId
        case price
        case date
        case createdAt
        case size
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Décode id
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else {
            id = ""
        }
        
        // Décode type (doit être "Purchased" ou "Sold")
        type = try container.decode(String.self, forKey: .type)
        
        // Décode clothesId
        clothesId = try container.decode(OrderClothInfo.self, forKey: .clothesId)
        
        // Décode price
        price = try container.decode(Double.self, forKey: .price)
        
        // Décode size (optionnel)
        size = try container.decodeIfPresent(String.self, forKey: .size)
        
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
    
    var isPurchased: Bool {
        type == "Purchased"
    }
    
    var isSold: Bool {
        type == "Sold"
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
        
        // Debug: Log response
        if let http = response as? HTTPURLResponse {
            print("🔍 [OrdersService] Transactions Status Code: \(http.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 [OrdersService] Transactions Response: \(jsonString.prefix(1000))")
            }
        }
        
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                throw NetworkError.serverMessage(message)
            }
            throw NetworkError.requestFailed(http.statusCode)
        }
        
        // ✨ VÉRIFICATION PRÉALABLE CRITIQUE : filtrer les orders AVANT le décodage
        // Les orders ont "clothesId" et "userId", les transactions ont "type" et "amount"
        // ✨ IMPORTANT : Les transactions ne doivent JAMAIS avoir "clothesId" ou "userId"
        var filteredData: Data = data
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            var validTransactions: [[String: Any]] = []
            var ordersFound = 0
            
            for (index, item) in jsonArray.enumerated() {
                // ✨ CRITIQUE : Si un élément a "clothesId" ou "userId", c'est un ORDER, on le REJETTE
                if item["clothesId"] != nil || item["userId"] != nil {
                    ordersFound += 1
                    print("🚫 [OrdersService] REJECTED: Found order in transactions response at index \(index)")
                    print("   Order has clothesId: \(item["clothesId"] != nil ? "YES" : "NO")")
                    print("   Order has userId: \(item["userId"] != nil ? "YES" : "NO")")
                    continue // Rejeter cet élément
                }
                
                // ✨ Vérifier que c'est bien une transaction (a "type" et "amount", PAS de "clothesId" ou "userId")
                if let type = item["type"] as? String,
                   let _ = item["amount"] as? Double,
                   (type == "incoming" || type == "outgoing"),
                   item["clothesId"] == nil, // ✨ Double vérification
                   item["userId"] == nil {   // ✨ Double vérification
                    // C'est une vraie transaction, on la garde
                    validTransactions.append(item)
                } else {
                    print("⚠️ [OrdersService] REJECTED: Invalid transaction structure at index \(index)")
                    print("   Missing type or amount, or invalid type, or has order fields")
                }
            }
            
            if ordersFound > 0 {
                print("🚨 [OrdersService] CRITICAL: Found and rejected \(ordersFound) orders in transactions endpoint!")
            }
            
            // Recréer les données avec uniquement les transactions valides
            if validTransactions.count != jsonArray.count {
                print("✅ [OrdersService] Filtered JSON: \(jsonArray.count) items -> \(validTransactions.count) valid transactions")
                if let newData = try? JSONSerialization.data(withJSONObject: validTransactions) {
                    filteredData = newData
                } else {
                    print("⚠️ [OrdersService] Failed to recreate filtered data, using original")
                }
            }
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
            // Décoder manuellement pour filtrer les orders qui pourraient être mélangés
            if let jsonArray = try? JSONSerialization.jsonObject(with: filteredData) as? [[String: Any]] {
                var validTransactions: [TransactionResponse] = []
                var rejectedCount = 0
                
                for (index, jsonObject) in jsonArray.enumerated() {
                    // ✨ CRITIQUE : Vérifier que ce n'est pas un order (a "clothesId" ou "userId")
                    if jsonObject["clothesId"] != nil || jsonObject["userId"] != nil {
                        rejectedCount += 1
                        print("🚫 [OrdersService] Rejected order at index \(index) (has clothesId or userId)")
                        continue
                    }
                    
                    // ✨ Vérifier que c'est bien une transaction (a "type" et "amount")
                    guard let type = jsonObject["type"] as? String,
                          type == "incoming" || type == "outgoing",
                          jsonObject["amount"] != nil else {
                        rejectedCount += 1
                        print("🚫 [OrdersService] Rejected invalid transaction at index \(index): missing type or amount")
                        continue
                    }
                    
                    // Essayer de décoder comme transaction
                    if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject) {
                        do {
                            let transaction = try decoder.decode(TransactionResponse.self, from: jsonData)
                            // ✨ Validation finale : s'assurer que c'est bien une transaction
                            if transaction.type == "incoming" || transaction.type == "outgoing" {
                                validTransactions.append(transaction)
                            } else {
                                rejectedCount += 1
                                print("🚫 [OrdersService] Rejected invalid transaction at index \(index): type='\(transaction.type)'")
                            }
                        } catch {
                            rejectedCount += 1
                            print("🚫 [OrdersService] Failed to decode transaction at index \(index): \(error)")
                        }
                    }
                }
                
                if rejectedCount > 0 {
                    print("⚠️ [OrdersService] Rejected \(rejectedCount) invalid items during decoding")
                }
                
                print("✅ [OrdersService] Successfully decoded \(validTransactions.count) valid transactions")
                return validTransactions
            } else {
                // Fallback: décodage normal si ce n'est pas un tableau
                // ✨ CRITIQUE : Filtrer AVANT le décodage pour rejeter les orders
                if let jsonArray = try? JSONSerialization.jsonObject(with: filteredData) as? [[String: Any]] {
                    var validTransactions: [TransactionResponse] = []
                    for jsonObject in jsonArray {
                        // ✨ REJETER tout élément qui a clothesId ou userId (c'est un order)
                        if jsonObject["clothesId"] != nil || jsonObject["userId"] != nil {
                            print("🚫 [OrdersService] Rejected order in fallback decoding (has clothesId or userId)")
                            continue
                        }
                        // Vérifier que c'est une transaction valide
                        guard let type = jsonObject["type"] as? String,
                              (type == "incoming" || type == "outgoing"),
                              jsonObject["amount"] != nil else {
                            print("🚫 [OrdersService] Rejected invalid transaction in fallback")
                            continue
                        }
                        // Décoder comme transaction
                        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject) {
                            if let transaction = try? decoder.decode(TransactionResponse.self, from: jsonData) {
                                validTransactions.append(transaction)
                            }
                        }
                    }
                    print("✅ [OrdersService] Decoded \(validTransactions.count) transactions successfully (fallback)")
                    return validTransactions
                } else {
                    // Dernier recours : décodage direct (mais avec filtrage)
                let transactions = try decoder.decode([TransactionResponse].self, from: filteredData)
                    print("✅ [OrdersService] Decoded \(transactions.count) transactions successfully (direct)")
                return transactions.filter { $0.type == "incoming" || $0.type == "outgoing" }
                }
            }
        } catch {
            print("❌ [OrdersService] Transactions decoding error: \(error)")
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
            // Retourner un tableau vide au lieu de faire échouer
            print("⚠️ [OrdersService] Returning empty array due to decoding error")
            return []
        }
    }
    
    // MARK: - Get Unified History
    func getUnifiedHistory() async throws -> [HistoryItemResponse] {
        guard let url = URL(string: APIConstants.baseURL.absoluteString + "/orders/history") else {
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
            print("🔍 [OrdersService] History Status Code: \(http.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 [OrdersService] History Response: \(jsonString.prefix(1000))")
            }
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
            let history = try decoder.decode([HistoryItemResponse].self, from: data)
            print("✅ [OrdersService] Decoded \(history.count) history items successfully")
            return history
        } catch {
            print("❌ [OrdersService] History decoding error: \(error)")
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
}

