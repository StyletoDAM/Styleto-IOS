// Models/Chat/ChatMessage.swift
import Foundation

struct ChatParticipant: Codable, Identifiable {
    let id: String
    let fullName: String
    let profilePicture: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case altId = "id"
        case fullName
        case profilePicture
    }
    
    // ⭐ Décodage flexible : accepte "_id" OU "id"
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Essayer "_id" en premier, sinon "id"
        if let objectId = try? container.decode(String.self, forKey: .id) {
            self.id = objectId
        } else if let simpleId = try? container.decode(String.self, forKey: .altId) {
            self.id = simpleId
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.id,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Ni _id ni id trouvé"
                )
            )
        }
        
        self.fullName = try container.decode(String.self, forKey: .fullName)
        self.profilePicture = try? container.decode(String.self, forKey: .profilePicture)
    }
    
    // ⭐ Encodage (nécessaire pour Encodable)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fullName, forKey: .fullName)
        try container.encodeIfPresent(profilePicture, forKey: .profilePicture)
    }
    
    // Constructeur manuel
    init(id: String, fullName: String, profilePicture: String?) {
        self.id = id
        self.fullName = fullName
        self.profilePicture = profilePicture
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let conversationId: String
    let senderId: ChatParticipant
    let content: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case conversationId
        case senderId
        case content
        case createdAt
    }
    
    // Constructeur manuel
    init(id: String = UUID().uuidString,
         conversationId: String,
         senderId: ChatParticipant,
         content: String,
         createdAt: Date = Date()) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.createdAt = createdAt
    }
    
    // Décodage flexible
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.conversationId = try container.decode(String.self, forKey: .conversationId)
        self.senderId = try container.decode(ChatParticipant.self, forKey: .senderId)
        self.content = try container.decode(String.self, forKey: .content)
        
        if let dateStr = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.createdAt = formatter.date(from: dateStr) ??
                            { formatter.formatOptions = [.withInternetDateTime]; return formatter.date(from: dateStr) }() ??
                            Date()
        } else if let timestamp = try? container.decode(Double.self, forKey: .createdAt) {
            self.createdAt = Date(timeIntervalSince1970: timestamp / 1000)
        } else {
            self.createdAt = Date()
        }
    }
}

// ⭐ IMPORTANT : Supprimez l'extension Equatable si elle existe déjà dans votre fichier
// Cette extension est nécessaire pour utiliser .contains() et ==
extension ChatMessage: Equatable {
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}
