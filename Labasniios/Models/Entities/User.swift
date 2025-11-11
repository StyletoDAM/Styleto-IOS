import Foundation

struct User: Codable, Identifiable {
    let id: String
    let fullName: String
    let email: String
    let gender: Gender
    let preferences: [String]
    let phoneNumber: String?
    let createdAt: Date?
    let updatedAt: Date?
    let authProvider: AuthProvider?
    let googleId: String?
    let appleId: String?
    let profilePicture: String?

    enum Gender: String, Codable {
        case male
        case female
    }

    enum AuthProvider: String, Codable {
        case local
        case google
        case apple
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
                    debugDescription: "Missing identifier in user payload"
                )
            )
        }
        fullName = try container.decode(String.self, forKey: .fullName)
        email = try container.decode(String.self, forKey: .email)
        gender = try container.decode(Gender.self, forKey: .gender)
        preferences = try container.decodeIfPresent([String].self, forKey: .preferences) ?? []
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        authProvider = try container.decodeIfPresent(AuthProvider.self, forKey: .authProvider)
        googleId = try container.decodeIfPresent(String.self, forKey: .googleId)
        appleId = try container.decodeIfPresent(String.self, forKey: .appleId)
        profilePicture = try container.decodeIfPresent(String.self, forKey: .profilePicture)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(email, forKey: .email)
        try container.encode(gender, forKey: .gender)
        try container.encode(preferences, forKey: .preferences)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(authProvider, forKey: .authProvider)
        try container.encodeIfPresent(googleId, forKey: .googleId)
        try container.encodeIfPresent(appleId, forKey: .appleId)
        try container.encodeIfPresent(profilePicture, forKey: .profilePicture)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case fullName
        case email
        case gender
        case preferences
        case phoneNumber
        case createdAt
        case updatedAt
        case authProvider
        case googleId
        case appleId
        case profilePicture
    }
}
