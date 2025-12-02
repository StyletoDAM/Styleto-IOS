import Foundation

// MARK: - ClotheUserInfo (objet complet pour Clothe)
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
        case imageURL, category, season, color, style, userId, acceptedCount, rejectedCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        season = try container.decodeIfPresent(String.self, forKey: .season)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        style = try container.decodeIfPresent(String.self, forKey: .style)
        
        // Decode acceptedCount and rejectedCount
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
