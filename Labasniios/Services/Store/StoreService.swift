//
//  StoreService.swift
//  Labasniios
//
//  Service pour la gestion du store (marketplace)
//
//  Ce fichier gère toutes les opérations liées au marketplace dans l'application :
//  - Récupération des articles du store (tous ou ceux de l'utilisateur)
//  - Création, mise à jour et suppression d'articles
//  - Gestion des paiements Stripe
//  - Confirmation des achats
//
//  Architecture : Singleton pattern avec Combine Publishers
//  Dépendances : Foundation, Combine, URLSession
//

import Foundation
import Combine

/**
 * Service pour la gestion du store (marketplace)
 * 
 * Cette classe implémente le pattern Singleton pour fournir un accès
 * global aux opérations du marketplace. Elle utilise Combine Publishers
 * pour une gestion réactive des données et des erreurs.
 * 
 * Les méthodes retournent des AnyPublisher pour permettre la composition
 * et la transformation des données de manière déclarative.
 */
class StoreService {
    /// Instance singleton partagée
    static let shared = StoreService()
    
    /// Initialiseur privé pour garantir le pattern Singleton
    private init() {}

    /// URL de base du backend
    private let baseURL = APIConstants.baseURL
    
    /// Gestionnaire de tokens pour l'authentification
    private let tokenManager = TokenManager.shared

    // MARK: - Fetch My Store Items
    func fetchMyStore() -> AnyPublisher<[Store], NetworkError> {
        guard let url = URL(string: "/store/my", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [Store].self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError { return .transport(urlError) }
                if let decodingError = error as? DecodingError {
                    print("Decoding error:", decodingError)
                    return .decodingFailed
                }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    // MARK: - Fetch All Store Items
    func fetchAllStoreItems() -> AnyPublisher<[Store], NetworkError> {
        guard let url = URL(string: "/store", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [Store].self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError { return .transport(urlError) }
                if let decodingError = error as? DecodingError {
                    print("Decoding error:", decodingError)
                    return .decodingFailed
                }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    // MARK: - Create Store Item
    func createStoreItem(body: [String: Any]) -> AnyPublisher<Store, NetworkError> {
        guard let url = URL(string: "/store", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: Store.self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError { return .transport(urlError) }
                if let decodingError = error as? DecodingError {
                    print("Decoding error:", decodingError)
                    return .decodingFailed
                }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    

    // MARK: - Update Store Item
    func updateStore(_ storeId: String, status: String) -> AnyPublisher<Void, NetworkError> {
        guard let url = URL(string: "/store/\(storeId)", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["status": status])

        return URLSession.shared.dataTaskPublisher(for: request)
            .map { _ in () }
            .mapError { _ in .serverError }
            .eraseToAnyPublisher()
    }
    // MARK: - Update Item Size (version finale, propre et qui marche partout)
    func updateStoreSize(_ storeId: String, size: String) -> AnyPublisher<Store, NetworkError> {
        guard let url = URL(string: "/store/\(storeId)", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // VERSION QUI MARCHE À 100% EN TUNISIE
        let body: [String: Any] = ["size": size]  // ← C'EST ÇA QUE TON BACKEND VEUT !

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: .serverError).eraseToAnyPublisher() // ← plus propre, pas d'erreur encodingFailed
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output -> Data in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw NetworkError.serverError
                }
                
                print("Status code mise à jour taille:", httpResponse.statusCode)
                if let responseString = String(data: output.data, encoding: .utf8) {
                    print("Réponse backend:", responseString)
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError
                }
                return output.data
            }
            .decode(type: Store.self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                print("Erreur mise à jour taille:", error)
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    
    
    // MARK: - Update Item Price
    func updateStorePrice(_ storeId: String, price: Double) -> AnyPublisher<Store, NetworkError> {
      guard let url = URL(string: "/store/\(storeId)", relativeTo: baseURL) else {
        return Fail(error: .invalidURL).eraseToAnyPublisher()
      }

      var request = URLRequest(url: url)
      request.httpMethod = "PATCH"
      request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")

      let body = ["price": price]
      request.httpBody = try? JSONSerialization.data(withJSONObject: body)

      return URLSession.shared.dataTaskPublisher(for: request)
        .map(\.data)
        .decode(type: Store.self, decoder: JSONDecoder())
        .mapError { _ in .serverError }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Mark Item As Sold
    func markAsSold(_ storeId: String) -> AnyPublisher<Store, NetworkError> {
        guard let url = URL(string: "/store/\(storeId)", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Envoyer le body avec le status
        let body = ["status": "sold"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw NetworkError.serverError
                }
                
                // Log pour debug
                print("Status code:", httpResponse.statusCode)
                
                guard httpResponse.statusCode == 200 else {
                    throw NetworkError.serverError
                }
                return output.data
            }
            .decode(type: Store.self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                print("Error marking as sold:", error)
                if let urlError = error as? URLError { return .transport(urlError) }
                if let decodingError = error as? DecodingError {
                    print("Decoding error:", decodingError)
                    return .decodingFailed
                }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    // MARK: - Delete Store Item
    func deleteStoreItem(_ storeId: String) -> AnyPublisher<Void, NetworkError> {
        guard let url = URL(string: "/store/\(storeId)", relativeTo: baseURL) else {
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
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
