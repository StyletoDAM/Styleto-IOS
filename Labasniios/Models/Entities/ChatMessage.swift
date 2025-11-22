// Models/Chat/ChatMessage.swift
import Foundation

struct ChatParticipant: Codable, Identifiable {
    let id: String
    let fullName: String
    let profilePicture: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fullName
        case profilePicture
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
    
    // Constructeur manuel pour envoyer un message (sans decoder)
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
    
    // Décodage flexible pour les dates
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
