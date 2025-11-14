import Foundation
import UIKit

final class ProfileService {
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    //Permet de lire les dates comme "2025-11-14T15:00:00.123Z"
    private static let iso8601Fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private struct ErrorResponse: Decodable {
        let statusCode: Int
        let message: String
    }
    
    init(session: URLSession = .shared) {
        self.session = session
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .useDefaultKeys
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = ProfileService.iso8601Fractional.date(from: value) {
                return date
            }
            if let date = ISO8601DateFormatter().date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected ISO8601 date string.")
        }
    }
    
    // MARK: - Update Text Profile (JSON)
    func updateProfileText(
        fullName: String? = nil,
        phoneNumber: String? = nil,
        gender: String? = nil,
        preferences: [String]? = nil,
        password: String? = nil
    ) async throws -> User {
        guard let token = TokenManager.shared.getToken() else {
            throw NetworkError.serverMessage("Token d'authentification manquant.")
        }
        
        let url = APIConstants.baseURL.appendingPathComponent("auth/profile")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(APIConstants.jsonContentType, forHTTPHeaderField: "Accept")
        
        // Construire le body JSON
        var body: [String: Any] = [:]
        if let fullName = fullName, !fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            body["fullName"] = fullName
        }
        if let phoneNumber = phoneNumber, !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty {
            body["phoneNumber"] = phoneNumber
        }
        if let gender = gender { body["gender"] = gender }
        if let password = password, !password.isEmpty { body["password"] = password }
        if let preferences = preferences, !preferences.isEmpty {
                body["preferences"] = preferences
            }
        if body.isEmpty {
            throw NetworkError.invalidData
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        debugPrint("[ProfileService] PATCH /auth/profile (text)")
        
        return try await performRequest(request)
    }
    
    // MARK: - Update Profile Photo (multipart)
    func updateProfilePhoto(image: UIImage) async throws -> User {
        guard let token = TokenManager.shared.getToken() else {
            throw NetworkError.serverMessage("Token d'authentification manquant.")
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.invalidData
        }
        
        let url = APIConstants.baseURL.appendingPathComponent("auth/profile/photo")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Image
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        debugPrint("[ProfileService] PATCH /auth/profile/photo (image: \(imageData.count) bytes)")
        
        return try await performRequest(request)
    }
    
    // MARK: - Helper: Perform Request
    private func performRequest(_ request: URLRequest) async throws -> User {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        let responseBodyString = String(data: data, encoding: .utf8) ?? "<non UTF-8>"
        debugPrint("[ProfileService] Status: \(httpResponse.statusCode)")
        debugPrint("[ProfileService] Body: \(responseBodyString)")
        
        switch httpResponse.statusCode {
        case 200..<300:
            do {
                return try decoder.decode(User.self, from: data)
            } catch {
                debugPrint("[ProfileService] decode error: \(error)")
                throw NetworkError.decodingFailed
            }
        case 401:
            throw NetworkError.serverMessage("Token invalide.")
        case 409:
            if let serverError = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverMessage(serverError.message)
            }
            throw NetworkError.serverMessage("Conflit.")
        default:
            if let serverError = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverMessage(serverError.message)
            }
            throw NetworkError.requestFailed(httpResponse.statusCode)
        }
    }
    // MARK: - Delete Profile
    func deleteProfile() async throws -> Bool {
        guard let token = TokenManager.shared.getToken() else {
            throw NetworkError.serverMessage("Token d'authentification manquant.")
        }
        
        let url = APIConstants.baseURL.appendingPathComponent("auth/profile")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        debugPrint("[ProfileService] DELETE /auth/profile")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        let responseBodyString = String(data: data, encoding: .utf8) ?? "<non UTF-8>"
        debugPrint("[ProfileService] Status: \(httpResponse.statusCode)")
        debugPrint("[ProfileService] Body: \(responseBodyString)")
        
        switch httpResponse.statusCode {
        case 200:
            return true
        case 401:
            throw NetworkError.serverMessage("Token invalide ou expiré.")
        case 404:
            throw NetworkError.serverMessage("Utilisateur introuvable.")
        default:
            if let serverError = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverMessage(serverError.message)
            }
            throw NetworkError.requestFailed(httpResponse.statusCode)
        }
    }

}


// Extension pour ajouter facilement une String à un objet Data
// Utile pour construire le body multipart/form-data lors de l'envoi d'une image
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
