//
//  ProfileService.swift
//  Labasniios
//
//  Created by MacBook on 2/11/2025.
//

import Foundation
import UIKit

final class ProfileService {
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private static let iso8601Fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private struct UpdateProfilePayload: Encodable {
        let fullName: String?
        let email: String?
        let phoneNumber: String?
        let gender: String?
        let preferences: [String]?
        let password: String?
        
        enum CodingKeys: String, CodingKey {
            case fullName
            case email
            case phoneNumber
            case gender
            case preferences
            case password
        }
    }
    
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
    
    /// Met à jour le profil avec champs + image optionnelle
    func updateProfile(
        fullName: String? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        gender: String? = nil,
        preferences: [String]? = nil,
        password: String? = nil,
        profileImage: UIImage? = nil
    ) async throws -> User {
        guard let token = TokenManager.shared.getToken() else {
            throw NetworkError.serverMessage("Token d'authentification manquant.")
        }
        
        var request = try makeRequest()
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Si image → multipart/form-data
        if let image = profileImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            // Ajouter les champs texte (seulement s’ils sont non-nil)
            let fields: [String: Any?] = [
                "fullName": fullName,
                "email": email,
                "phoneNumber": phoneNumber,
                "gender": gender,
                "preferences": preferences,
                "password": password
            ]
            
            for (key, value) in fields {
                if let value = value {
                    body.append("--\(boundary)\r\n")
                    body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                    body.append("\(value)\r\n")
                }
            }
            
            // Ajouter l'image
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
            body.append("--\(boundary)--\r\n")
            
            request.httpBody = body
            
            debugPrint("[ProfileService] PATCH \(request.url?.absoluteString ?? "") avec image")
            debugPrint("[ProfileService] Image size: \(imageData.count) bytes")
        }
        // Sinon → JSON classique
        else {
            let payload = UpdateProfilePayload(
                fullName: fullName,
                email: email,
                phoneNumber: phoneNumber,
                gender: gender,
                preferences: preferences,
                password: password
            )
            request.httpBody = try encoder.encode(payload)
            debugPrint("[ProfileService] PATCH \(request.url?.absoluteString ?? "") sans image")
            debugPrint("[ProfileService] Payload: \(payload)")
        }
        
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
            throw NetworkError.serverMessage("Token d'authentification invalide.")
        case 409:
            if let serverError = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverMessage(serverError.message)
            }
            throw NetworkError.serverMessage("Email déjà utilisé.")
        default:
            if let serverError = try? decoder.decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverMessage(serverError.message)
            }
            throw NetworkError.requestFailed(httpResponse.statusCode)
        }
    }
    
    private func makeRequest() throws -> URLRequest {
        guard let url = URL(string: "/auth/profile", relativeTo: APIConstants.baseURL) else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue(APIConstants.jsonContentType, forHTTPHeaderField: "Accept")
        return request
    }
}

// Extension pour append String → Data
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
