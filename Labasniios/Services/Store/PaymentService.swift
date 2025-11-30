import Foundation
import Combine

final class PaymentService {
    static let shared = PaymentService()
    
    private let baseURL = APIConstants.baseURL
    private let tokenManager = TokenManager.shared
    
    private init() {}
    
    // MARK: - Create REAL Payment Intent (STRIPE UI)
    
    /// Crée un payment intent RÉEL via Stripe
    func createPaymentIntent(amount: Double, currency: String = "usd") async throws -> String {
        guard let url = URL(string: "/store/payment-intent", relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "amount": amount,
            "currency": currency
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📤 [PaymentService] Creating REAL Stripe Payment Intent")
        print("   💰 Amount: \(amount) \(currency)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }
        
        print("📡 [PaymentService] Status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 [PaymentService] Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }
        
        // Parser la réponse : { clientSecret: "pi_xxx_secret_yyy" }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let clientSecret = json["clientSecret"] as? String else {
            print("❌ [PaymentService] Failed to parse clientSecret")
            throw NetworkError.decodingFailed
        }
        
        print("✅ [PaymentService] Client Secret received!")
        
        return clientSecret
    }
    
    // MARK: - Confirm Purchase
    
    /// Confirme l'achat après paiement Stripe réussi
    func confirmPurchase(storeItemId: String, paymentMethod: String, paymentIntentId: String? = nil) async throws -> Store {
        guard let url = URL(string: "/store/purchase/\(storeItemId)", relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["paymentMethod": paymentMethod]
        if let paymentIntentId = paymentIntentId {
            body["paymentIntentId"] = paymentIntentId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorStr = String(data: data, encoding: .utf8) ?? ""
            if errorStr.contains("Solde insuffisant") || errorStr.contains("insuffisant") {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Solde insuffisant"])
            }
            throw NetworkError.serverError
        }
        
        return try JSONDecoder().withISO8601().decode(Store.self, from: data)
    }
}
