//
//  VTOClothesService.swift
//  Labasniios
//
//  Created by Aziz on 6/12/2025.
//

import Foundation
import Combine

class VTOClothesService {
    static let shared = VTOClothesService()
    
    private let baseURL = APIConstants.baseURL
    private let tokenManager = TokenManager.shared
    
    private init() {}
    
    // MARK: - Fetch VTO Ready Clothes
    /// Récupère les vêtements prêts pour le VTO (groupés par catégorie)
    func fetchVTOReadyClothes() async throws -> [String: [VTOClothe]] {
        guard let url = URL(string: "\(baseURL)/clothes/vto/ready") else {
            throw URLError(.badURL)
        }
        
        guard let token = tokenManager.getToken() else {
            throw NSError(domain: "", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "Non authentifié"
            ])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Erreur serveur"
            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: errorMsg
            ])
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(VTOReadyClothesResponse.self, from: data)
        
        return result.data
    }
    
    // MARK: - Fetch Batch Clothes
    /// Récupère plusieurs vêtements par leurs IDs
    func fetchBatchClothes(ids: [String]) async throws -> [VTOClothe] {
        guard let url = URL(string: "\(baseURL)/clothes/vto/batch") else {
            throw URLError(.badURL)
        }
        
        guard let token = tokenManager.getToken() else {
            throw NSError(domain: "", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "Non authentifié"
            ])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["clothingIds": ids]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(VTOBatchResponse.self, from: data)
        
        return result.data
    }
    
    // MARK: - Reprocess Clothing
    /// Relance le traitement d'une image
    func reprocessClothing(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/clothes/\(id)/reprocess") else {
            throw URLError(.badURL)
        }
        
        guard let token = tokenManager.getToken() else {
            throw NSError(domain: "", code: 401)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}
