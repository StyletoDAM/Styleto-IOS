//
//  OutfitsService.swift
//  Labasniios
//
//  Service pour la gestion des tenues (outfits)
//
//  Ce fichier gère toutes les opérations liées aux tenues dans l'application :
//  - Récupération des tenues de l'utilisateur
//  - Génération de recommandations d'outfits par IA
//  - Création de nouvelles tenues
//  - Gestion des favoris
//
//  Architecture : Singleton pattern avec Combine Publishers
//  Dépendances : Foundation, Combine, URLSession
//

import Foundation
import Combine

/**
 * Service pour la gestion des tenues (outfits)
 * 
 * Cette classe implémente le pattern Singleton pour fournir un accès
 * global aux opérations sur les tenues. Elle utilise Combine Publishers
 * pour une gestion réactive des données et des erreurs.
 * 
 * Les méthodes retournent des AnyPublisher pour permettre la composition
 * et la transformation des données de manière déclarative.
 */
class OutfitsService {
    /// Instance singleton partagée
    static let shared = OutfitsService()
    
    /// Initialiseur privé pour garantir le pattern Singleton
    private init() {}
 
    /// URL de base du backend
    private let baseURL = APIConstants.baseURL
    
    /// Gestionnaire de tokens pour l'authentification
    private let tokenManager = TokenManager.shared
 
    // MARK: - Fetch User Authenticated Outfits
    func fetchMyOutfits() -> AnyPublisher<[Outfit], NetworkError> {
        guard let url = URL(string: APIConstants.outfitsMyPath, relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }
 
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
 
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .handleEvents(receiveOutput: { data in
                if let json = try? JSONSerialization.jsonObject(with: data) {
                    print("📦 Outfits response:", json)
                }
            })
            .decode(type: [Outfit].self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError {
                    return .transport(urlError)
                } else if let decodingError = error as? DecodingError {
                    print("❌ Decoding error:", decodingError)
                    return .decodingFailed
                }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
 
    // MARK: - AI Recommendation
    func getAIRecommendation(style: String, city: String? = nil, temperature: Double? = nil) -> AnyPublisher<AIRecommendationResponse, NetworkError> {
        guard let url = URL(string: APIConstants.recommendationsPath, relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }
 
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
 
        var body: [String: Any] = ["preference": style.lowercased()]
        if let city = city {
            body["city"] = city
        }
        if let temp = temperature {
            body["temperature"] = temp
        }
 
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
 
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.serverError
                }
                
                // ✅ Si c'est une erreur HTTP, extraire le message du backend
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorJson["message"] as? String {
                        print("❌ Backend error message:", message)
                        throw NetworkError.serverMessage(message)
                    }
                    throw NetworkError.serverError
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) {
                    print("🤖 AI Recommendation response:", json)
                }
                return data
            }
            .decode(type: AIRecommendationResponse.self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    return networkError
                } else if let urlError = error as? URLError {
                    return .transport(urlError)
                } else if let decodingError = error as? DecodingError {
                    print("❌ Decoding error:", decodingError)
                    return .decodingFailed
                }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
 
    // MARK: - Create Outfit (Accept Suggestion)
    // ✅ Version avec eventType (style choisi)
    func createOutfit(clothesIds: [String], style: String? = nil) -> AnyPublisher<SimpleOutfitResponse, NetworkError> {
        guard let url = URL(string: APIConstants.outfitsPath, relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }
 
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
 
        // ✅ Ajouter le style comme eventType
        var body: [String: Any] = ["clothesIds": clothesIds]
        if let style = style {
            body["eventType"] = style.capitalized
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
 
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.serverError
                }
                
                print("📡 Create Outfit Status Code:", httpResponse.statusCode)
                
                // ✅ Si c'est 201 ou 200, c'est un succès
                if (200...299).contains(httpResponse.statusCode) {
                    if let json = try? JSONSerialization.jsonObject(with: data) {
                        print("✅ Create Outfit Response:", json)
                    }
                    return data
                } else {
                    print("❌ HTTP Error:", httpResponse.statusCode)
                    throw NetworkError.serverError
                }
            }
            .decode(type: SimpleOutfitResponse.self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    return networkError
                } else if let urlError = error as? URLError {
                    return .transport(urlError)
                } else if let decodingError = error as? DecodingError {
                    print("❌ Decoding error:", decodingError)
                    // ✅ Si le décodage échoue mais que le statut était 200/201, c'est quand même un succès
                    return .decodingFailed
                }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
 
    // MARK: - Update Outfit Status
    func updateOutfitStatus(_ outfitId: String, status: String) -> AnyPublisher<Void, NetworkError> {
        guard let url = URL(string: "\(APIConstants.outfitsPath)/\(outfitId)", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }
 
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
 
        let body = ["status": status]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
 
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { _ in () }
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError { return .transport(urlError) }
                return .serverError
            }
            .eraseToAnyPublisher()
    }
 
    // MARK: - Delete Outfit
    func deleteOutfit(_ outfitId: String) -> AnyPublisher<Void, NetworkError> {
        guard let url = URL(string: "\(APIConstants.outfitsPath)/\(outfitId)", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }
 
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
 
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { _ in () }
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError { return .transport(urlError) }
                return .serverError
            }
            .eraseToAnyPublisher()
    }
    // MARK: - Update Outfit Feedback (tous les vêtements)
    func updateOutfitFeedback(clothesIds: [String], accepted: Bool) -> AnyPublisher<Void, NetworkError> {
        let publishers = clothesIds.map { clotheId in
            ClothesService.shared.updateFeedback(clotheId: clotheId, accepted: accepted)
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
 
// MARK: - Simple Outfit Response (minimal)
// ✅ Structure minimale pour la création, on ne compte que sur l'ID
struct SimpleOutfitResponse: Codable {
    let _id: String?
    let id: String?
    let status: String?
    
    var outfitId: String {
        return _id ?? id ?? ""
    }
}
 
// MARK: - AI Recommendation Response Model
struct AIRecommendationResponse: Codable {
    let success: Bool
    let outfit: AIOutfitItems
    let metadata: AIMetadata
    let clothesIds: [String]
}
 
struct AIOutfitItems: Codable {
    let top: Clothe
    let bottom: Clothe
    let footwear: Clothe
}
 
struct AIMetadata: Codable {
    let weather: WeatherInfo
    let season: String
    let preference: String
    let explanation: AIExplanation?
}
 
struct WeatherInfo: Codable {
    let temperature: Double
    let condition: String
    let city: String?
}
 
struct AIExplanation: Codable {
    let top: ExplanationDetail
    let bottom: ExplanationDetail
    let footwear: ExplanationDetail
}
 
struct ExplanationDetail: Codable {
    let reason: String
    let score: Double
    let visualSimilarity: Double?
    let colorCompatibility: Double?
    let totalScore: Double?
}
 
// Extension pour ISO8601
extension JSONDecoder {
    func withISO8601() -> JSONDecoder {
        self.dateDecodingStrategy = .iso8601
        return self
    }
}
