// Services/Store/ChatService.swift
import Foundation

class ChatService {
    static let shared = ChatService()
    private let baseURL = APIConstants.baseURL
    
    private init() {}
    
    func fetchMyConversations() async throws -> [ChatConversationResponse] {
        guard let token = TokenManager.shared.getToken() else {
            throw NetworkError.unauthorized  // ← maintenant ça existe
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
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
               let message = errorResponse.message ?? errorResponse.error {
                throw NetworkError.serverMessage(message)
            }
            throw NetworkError.requestFailed(httpResponse.statusCode)default:
            throw NetworkError.serverError
        }
        
        guard !data.isEmpty else {
            throw NetworkError.noData
        }
        
        do {
            let conversations = try JSONDecoder().decode([ChatConversationResponse].self, from: data)
            return conversations
        } catch {
            print("Erreur décodage:", error)
            throw NetworkError.decodingFailed
        }
    }
}
