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
    var balance: Double?

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
        
        // ON ESSAIE "id" EN PREMIER (le serveur l'envoie maintenant)
        if container.contains(.id) {
            id = try container.decode(String.self, forKey: .id)
        } else if container.contains(.mongoId) {
            id = try container.decode(String.self, forKey: .mongoId)
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.id,
                .init(codingPath: [], debugDescription: "Aucun champ 'id' ou '_id' trouvé dans la réponse")
            )
        }
        
        fullName = try container.decode(String.self, forKey: .fullName)
        email = try container.decode(String.self, forKey: .email)
        
        // GENDER : le serveur envoie "female" comme String
        let genderStr = try container.decode(String.self, forKey: .gender)
        gender = Gender(rawValue: genderStr.lowercased()) ?? .female
        
        preferences = try container.decodeIfPresent([String].self, forKey: .preferences) ?? []
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        authProvider = try container.decodeIfPresent(AuthProvider.self, forKey: .authProvider)
        googleId = try container.decodeIfPresent(String.self, forKey: .googleId)
        appleId = try container.decodeIfPresent(String.self, forKey: .appleId)
        profilePicture = try container.decodeIfPresent(String.self, forKey: .profilePicture)
        balance = try container.decodeIfPresent(Double.self, forKey: .balance)
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
        try container.encodeIfPresent(balance, forKey: .balance)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case mongoId = "_id"
        case fullName, email, gender, preferences, phoneNumber
        case createdAt, updatedAt, authProvider, googleId, appleId
        case profilePicture, balance
    }
}
