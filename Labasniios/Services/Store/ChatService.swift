import Foundation

class ChatService {
    static let shared = ChatService()
    private let baseURL = APIConstants.baseURL
    
    private init() {}
    
    // Créer ou récupérer une conversation avec un vendeur
    func createOrGetConversation(withUserId participantId: String) async throws -> ChatConversationResponse {
        guard let token = TokenManager.shared.getToken() else {
            throw NetworkError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/chat/conversations") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["participantId": participantId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("📤 Création/récupération conversation avec:", participantId)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.transport(URLError(.badServerResponse))
        }
        
        print("📡 Status code:", httpResponse.statusCode)
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw NetworkError.unauthorized
        case 400...499:
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                let message = errorResponse.error ?? errorResponse.message
                throw NetworkError.serverMessage(message)
            }
            throw NetworkError.requestFailed(httpResponse.statusCode)
        default:
            throw NetworkError.serverError
        }
        
        do {
            let decoder = JSONDecoder()
            var conversation = try decoder.decode(ChatConversationResponse.self, from: data)
            
            print("✅ Conversation créée/récupérée:", conversation.id)
            print("📝 Participants:", conversation.participants.map { $0.id })
            
            // Récupérer les infos complètes des participants
            conversation = try await enrichParticipants(conversation)
            
            return conversation
            
        } catch {
            print("❌ Erreur décodage conversation:", error)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON reçu:", jsonString)
            }
            throw NetworkError.decodingFailed
        }
    }
    
    // NOUVELLE MÉTHODE : Enrichir les participants avec leurs infos complètes
    private func enrichParticipants(_ conversation: ChatConversationResponse) async throws -> ChatConversationResponse {
        var enrichedParticipants: [ChatParticipant] = []
        
        for participant in conversation.participants {
            // Si le participant n'a que l'ID, on récupère ses infos
            if participant.fullName == "Utilisateur" {
                do {
                    let userInfo = try await fetchUserInfo(userId: participant.id)
                    enrichedParticipants.append(userInfo)
                } catch {
                    print("⚠️ Impossible de récupérer les infos de \(participant.id), on garde la version minimale")
                    enrichedParticipants.append(participant)
                }
            } else {
                enrichedParticipants.append(participant)
            }
        }
        
        // Créer une nouvelle conversation avec les participants enrichis
        return ChatConversationResponse(
            id: conversation.id,
            participants: enrichedParticipants,
            isGroup: conversation.isGroup,
            messages: conversation.messages,
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt
        )
    }
    
    // Récupérer les infos d'un utilisateur
    private func fetchUserInfo(userId: String) async throws -> ChatParticipant {
        guard let token = TokenManager.shared.getToken() else {
            throw NetworkError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/users/\(userId)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Décoder la réponse utilisateur
        let decoder = JSONDecoder()
        let userResponse = try decoder.decode(UserInfoResponse.self, from: data)
        
        return ChatParticipant(
            id: userResponse.id,
            fullName: userResponse.fullName,
            profilePicture: userResponse.profilePicture
        )
    }
    
    // NOUVELLE MÉTHODE : Récupérer les messages d'une conversation
    func fetchMessages(conversationId: String) async throws -> [ChatMessage] {
        guard let token = TokenManager.shared.getToken() else {
            throw NetworkError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/chat/conversations/\(conversationId)/messages") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("📡 Récupération des messages pour:", conversationId)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.transport(URLError(.badServerResponse))
        }
        
        print("📡 Status code:", httpResponse.statusCode)
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw NetworkError.unauthorized
        case 400...499:
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                let message = errorResponse.error ?? errorResponse.message
                throw NetworkError.serverMessage(message)
            }
            throw NetworkError.requestFailed(httpResponse.statusCode)
        default:
            throw NetworkError.serverError
        }
        
        do {
            let decoder = JSONDecoder()
            let messages = try decoder.decode([ChatMessage].self, from: data)
            print("✅ \(messages.count) messages récupérés")
            return messages
        } catch {
            print("❌ Erreur décodage messages:", error)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON reçu:", jsonString)
            }
            throw NetworkError.decodingFailed
        }
    }
    
    // Récupérer toutes mes conversations
    func fetchMyConversations() async throws -> [ChatConversationResponse] {
        guard let token = TokenManager.shared.getToken() else {
            throw NetworkError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/chat/conversations") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.transport(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw NetworkError.unauthorized
        case 400...499:
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                let message = errorResponse.error ?? errorResponse.message
                throw NetworkError.serverMessage(message)
            }
            throw NetworkError.requestFailed(httpResponse.statusCode)
        default:
            throw NetworkError.serverError
        }
        
        guard !data.isEmpty else {
            throw NetworkError.noData
        }
        
        do {
            let conversations = try JSONDecoder().decode([ChatConversationResponse].self, from: data)
            return conversations
        } catch {
            print("❌ Erreur décodage conversations:", error)
            throw NetworkError.decodingFailed
        }
    }
}

// Modèle pour la réponse utilisateur
struct UserInfoResponse: Codable {
    let id: String
    let fullName: String
    let profilePicture: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fullName
        case profilePicture
    }
}

// Extension pour permettre la création manuelle de ChatConversationResponse
extension ChatConversationResponse {
    init(id: String, participants: [ChatParticipant], isGroup: Bool, messages: [ChatMessage], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.participants = participants
        self.isGroup = isGroup
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
