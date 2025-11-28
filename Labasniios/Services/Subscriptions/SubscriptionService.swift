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
}
