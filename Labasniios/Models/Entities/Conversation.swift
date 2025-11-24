import Foundation

struct ChatConversationResponse: Codable, Identifiable, Equatable {
    let id: String
    var participants: [ChatParticipant]
    let isGroup: Bool
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case participants
        case isGroup
        case messages
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.isGroup = try container.decode(Bool.self, forKey: .isGroup)
        
        // ⭐ DÉCODAGE FLEXIBLE DES PARTICIPANTS
        // Cas 1 : Liste de strings (IDs uniquement) → on crée des participants minimaux
        if let participantIds = try? container.decode([String].self, forKey: .participants) {
            print("📝 Participants reçus comme IDs:", participantIds)
            self.participants = participantIds.map { id in
                ChatParticipant(id: id, fullName: "Utilisateur", profilePicture: nil)
            }
        }
        // Cas 2 : Liste d'objets complets
        else if let participantObjects = try? container.decode([ChatParticipant].self, forKey: .participants) {
            print("📝 Participants reçus comme objets:", participantObjects.count)
            self.participants = participantObjects
        }
        else {
            throw DecodingError.typeMismatch(
                [ChatParticipant].self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Impossible de décoder participants (ni String[] ni ChatParticipant[])"
                )
            )
        }
        
        // Messages (peut être vide)
        self.messages = (try? container.decode([ChatMessage].self, forKey: .messages)) ?? []
        
        // Dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let createdAtStr = try? container.decode(String.self, forKey: .createdAt) {
            self.createdAt = dateFormatter.date(from: createdAtStr) ?? Date()
        } else {
            self.createdAt = Date()
        }
        
        if let updatedAtStr = try? container.decode(String.self, forKey: .updatedAt) {
            self.updatedAt = dateFormatter.date(from: updatedAtStr) ?? Date()
        } else {
            self.updatedAt = Date()
        }
    }
    
    static func == (lhs: ChatConversationResponse, rhs: ChatConversationResponse) -> Bool {
        lhs.id == rhs.id
    }
}
