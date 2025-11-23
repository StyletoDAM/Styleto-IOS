import Foundation

struct Store: Codable, Identifiable, Equatable {  // ✅ Ajout Equatable
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
    
    let clothe: Clothe?
    let user: User?
    
    enum StoreStatus: String, Codable {
        case available
        case sold
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
