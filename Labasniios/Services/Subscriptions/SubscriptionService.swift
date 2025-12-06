// Services/Subscriptions/SubscriptionService.swift
import Foundation

class SubscriptionService {
    static let shared = SubscriptionService()
    private init() {}
    
    func getMySubscription() async throws -> SubscriptionResponse {
        guard let url = URL(string: APIConstants.baseURL.absoluteString + "/subscriptions/me") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder.iso8601.decode(SubscriptionResponse.self, from: data)
    }
    
    func getUsageStats() async throws -> UsageStatsResponse {
        guard let url = URL(string: APIConstants.baseURL.absoluteString + "/subscriptions/me/stats") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder.iso8601.decode(UsageStatsResponse.self, from: data)
    }
    
    func canDetectClothes() async throws -> QuotaCheckResult {
        try await checkQuota(endpoint: "/subscriptions/quota/clothes-detection")
    }
    
    func canGenerateOutfit() async throws -> QuotaCheckResult {
        try await checkQuota(endpoint: "/subscriptions/quota/outfit-generation")
    }
    
    func canSellItem() async throws -> QuotaCheckResult {
        try await checkQuota(endpoint: "/subscriptions/quota/store-selling")
    }
    
    private func checkQuota(endpoint: String) async throws -> QuotaCheckResult {
        guard let url = URL(string: APIConstants.baseURL.absoluteString + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder.iso8601.decode(QuotaCheckResult.self, from: data)
    }
    
    // ✨ NOUVEAU: Annuler l'abonnement à la fin de la période
    func cancelSubscription() async throws -> CancelSubscriptionResponse {
        guard let url = URL(string: APIConstants.baseURL.absoluteString + "/subscriptions/cancel") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("📤 [SubscriptionService] Canceling subscription")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }
        
        print("📡 [SubscriptionService] Cancel Status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 [SubscriptionService] Cancel Response: \(responseString)")
        }
        
        if httpResponse.statusCode >= 400 {
            if let error = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverMessage(error.message)
            }
            throw NetworkError.requestFailed(httpResponse.statusCode)
        }
        
        let cancelResponse = try JSONDecoder.iso8601.decode(CancelSubscriptionResponse.self, from: data)
        print("✅ [SubscriptionService] Subscription will be canceled at: \(cancelResponse.expiresAt ?? Date())")
        
        return cancelResponse
    }
    
    // ANCIEN: Méthode conservée pour compatibilité
    func purchasePlan(_ plan: SubscriptionPlan, paymentData: PurchaseSimulationRequest) async throws -> PurchaseSimulationResponse {
        guard let url = URL(string: APIConstants.baseURL.absoluteString + "/subscriptions/purchase/\(plan.rawValue)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(paymentData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            if let error = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverMessage(error.message)
            }
            throw NetworkError.requestFailed(http.statusCode)
        }
        
        return try JSONDecoder.iso8601.decode(PurchaseSimulationResponse.self, from: data)
    }
    
    // ANCIEN: Mise à jour manuelle (Admin/Debug)
    func updateSubscription(plan: SubscriptionPlan) async throws -> SubscriptionResponse {
        guard let url = URL(string: APIConstants.baseURL.absoluteString + "/subscriptions/me") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["plan": plan.rawValue]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let http = response as? HTTPURLResponse {
            print("🔍 [SubscriptionService] PATCH /subscriptions/me Status: \(http.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 [SubscriptionService] Response: \(jsonString)")
            }
        }
        
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            if let error = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverMessage(error.message)
            }
            throw NetworkError.requestFailed(http.statusCode)
        }
        
        struct UpdateSubscriptionResponse: Codable {
            let message: String?
            let subscription: SubscriptionResponse
        }
        
        do {
            let wrapper = try JSONDecoder.iso8601.decode(UpdateSubscriptionResponse.self, from: data)
            print("✅ [SubscriptionService] Subscription updated successfully: \(wrapper.subscription.plan.rawValue)")
            return wrapper.subscription
        } catch {
            print("❌ [SubscriptionService] Decoding error: \(error)")
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                print("⚠️ [SubscriptionService] Decoding failed but status is OK, returning default response")
                return SubscriptionResponse(
                    plan: plan,
                    subscribedAt: Date(),
                    expiresAt: nil,
                    isActive: true
                )
            }
            throw error
        }
    }
}

// MARK: - Response Models

// ✨ NOUVEAU: Response pour l'annulation
struct CancelSubscriptionResponse: Codable {
    let success: Bool
    let message: String
    let expiresAt: Date?
    let status: String? // ✨ Ajout du statut
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decode(String.self, forKey: .message)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
        
        // expiresAt est optionnel
        if let date = try? container.decodeIfPresent(Date.self, forKey: .expiresAt) {
            expiresAt = date
        } else if let dateString = try? container.decodeIfPresent(String.self, forKey: .expiresAt), !dateString.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                expiresAt = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                expiresAt = formatter.date(from: dateString)
            }
        } else {
            expiresAt = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case success, message, expiresAt, status
    }
}

