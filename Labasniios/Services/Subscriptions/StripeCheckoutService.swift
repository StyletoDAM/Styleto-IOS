// Labasniios/Services/Subscriptions/StripeCheckoutService.swift
// 📌 NOUVEAU FICHIER - Créer ce fichier dans Xcode

import Foundation

/// Service dédié aux Stripe Checkout Sessions pour les abonnements
final class StripeCheckoutService {
    static let shared = StripeCheckoutService()
    
    private let baseURL = APIConstants.baseURL
    private let tokenManager = TokenManager.shared
    
    private init() {}
    
    // MARK: - Create Checkout Session
    
    /// Crée une session Stripe Checkout pour un abonnement
    /// - Parameters:
    ///   - plan: Le plan d'abonnement (PREMIUM ou PRO_SELLER)
    ///   - interval: Intervalle de facturation (month ou year)
    /// - Returns: URL de checkout et session ID
    func createCheckoutSession(
        plan: SubscriptionPlan,
        interval: BillingInterval = .month
    ) async throws -> CheckoutSessionResponse {
        guard let url = URL(string: "/subscriptions/create-checkout-session", relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "plan": plan.rawValue,
            "interval": interval.rawValue
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📤 [StripeCheckout] Creating checkout session")
        print("   📦 Plan: \(plan.rawValue)")
        print("   📅 Interval: \(interval.rawValue)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }
        
        print("📡 [StripeCheckout] Status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 [StripeCheckout] Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorJson["message"] as? String {
                throw NetworkError.serverMessage(message)
            }
            throw NetworkError.serverError
        }
        
        let decoder = JSONDecoder()
        let checkoutResponse = try decoder.decode(CheckoutSessionResponse.self, from: data)
        
        print("✅ [StripeCheckout] Checkout session created")
        print("   🔗 URL: \(checkoutResponse.checkoutUrl ?? "nil")")
        print("   🆔 Session ID: \(checkoutResponse.sessionId)")
        
        return checkoutResponse
    }
    
    // MARK: - Verify Session (optionnel, car géré par le webhook + success page)
    
    /// Vérifie le statut d'une session après redirection
    func verifySession(sessionId: String) async throws -> VerifySessionResponse {
        guard let url = URL(string: "/subscriptions/verify-session?sessionId=\(sessionId)", relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        
        print("📤 [StripeCheckout] Verifying session: \(sessionId)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }
        
        print("📡 [StripeCheckout] Verify Status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(VerifySessionResponse.self, from: data)
    }
}

// MARK: - Models

enum BillingInterval: String, Codable {
    case month = "month"
    case year = "year"
}

struct CheckoutSessionResponse: Codable {
    let checkoutUrl: String?
    let sessionId: String
    let displayPrice: String
    let plan: String
    let interval: String
}

struct VerifySessionResponse: Codable {
    let success: Bool
    let message: String
    let plan: String?
    let subscriptionId: String?
}
