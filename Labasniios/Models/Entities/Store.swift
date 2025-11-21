import Foundation

struct Store: Identifiable, Codable {
    let id: String
    let userId: UserReference
    let clothesId: ClotheReference
    var price: Double
    var status: String
    var size: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, clothesId, price, status,size, createdAt, updatedAt
    }
    
    var title: String {
        clothe?.category ?? "Unknown"
    }
    
    var dateLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var isAvailable: Bool {
        status == "available"
    }
    
    var userInfo: UserInfo? {
        if case .userInfo(let info) = userId {
            return info
        }
        return nil
    }
    
    var clothe: Clothe? {
        if case .clothe(let clothe) = clothesId {
            return clothe
        }
        return nil
    }
}

enum ClotheReference: Codable {
    case clotheId(String)
    case clothe(Clothe)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self = .clotheId(stringValue)
            return
        }
        
        if let clothe = try? container.decode(Clothe.self) {
            self = .clothe(clothe)
            return
        }
        
        throw DecodingError.typeMismatch(
            ClotheReference.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected String or Clothe"
            )
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .clotheId(let id):
            try container.encode(id)
        case .clothe(let clothe):
            try container.encode(clothe)
        }
    }
}

enum UserReference: Codable {
    case userId(String)
    case userInfo(UserInfo)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self = .userId(stringValue)
            return
        }
        
        if let userInfo = try? container.decode(UserInfo.self) {
            self = .userInfo(userInfo)
            return
        }
        
        throw DecodingError.typeMismatch(
            UserReference.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected String or UserInfo"
            )
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .userId(let id):
            try container.encode(id)
        case .userInfo(let info):
            try container.encode(info)
        }
    }
}
