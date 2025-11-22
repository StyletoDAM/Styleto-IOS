// Models/Chat/Conversation.swift
import Foundation

struct ChatConversationResponse: Codable, Identifiable {
    let id: String
    let participants: [ChatParticipant]
    let lastMessage: ChatMessage?
    let updatedAt: Date
    let createdAt: Date
    let messages: [ChatMessage]
    let messageCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case participants, lastMessage, updatedAt, createdAt, messages, messageCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.participants = try container.decode([ChatParticipant].self, forKey: .participants)
        self.lastMessage = try container.decodeIfPresent(ChatMessage.self, forKey: .lastMessage)
        self.messages = try container.decode([ChatMessage].self, forKey: .messages)
        self.messageCount = try container.decode(Int.self, forKey: .messageCount)
        
        let dateFrom = { (key: CodingKeys) -> Date in
            if let str = try? container.decode(String.self, forKey: key),
               let date = ISO8601DateFormatter().date(from: str) { return date }
            if let ts = try? container.decode(Double.self, forKey: key) { return Date(timeIntervalSince1970: ts / 1000) }
            return Date()
        }
        self.updatedAt = dateFrom(.updatedAt)
        self.createdAt = dateFrom(.createdAt)
    }
}
