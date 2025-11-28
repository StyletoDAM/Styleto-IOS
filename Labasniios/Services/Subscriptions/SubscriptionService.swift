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
    
    // Ancienne méthode (conservée pour compatibilité si nécessaire)
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
    
    // Nouvelle méthode utilisant PATCH /subscriptions/me (comme Android)
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
        
        // Body: { "plan": "PREMIUM" } ou { "plan": "PRO_SELLER" }
        let body: [String: String] = ["plan": plan.rawValue]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug: Log response
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
        
        // Le backend renvoie { message: string, subscription: SubscriptionResponse }
        // Il faut extraire "subscription" de la réponse
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
            // Si le décodage échoue mais que le status code est 200, on considère que c'est OK
            // et on retourne une réponse par défaut
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                print("⚠️ [SubscriptionService] Decoding failed but status is OK, returning default response")
                // Retourner une réponse par défaut
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
