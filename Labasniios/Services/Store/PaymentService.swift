import Foundation
import Combine

final class PaymentService {
    static let shared = PaymentService()
    
    private let baseURL = APIConstants.baseURL
    private let tokenManager = TokenManager.shared
    
    //  Stocker le dernier client secret créé
    private(set) var lastClientSecret: String?
    
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
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let clientSecret = json["clientSecret"] as? String else {
            print("❌ [PaymentService] Failed to parse clientSecret")
            throw NetworkError.decodingFailed
        }
        
        //  Stocker le client secret
        self.lastClientSecret = clientSecret
        
        print("✅ [PaymentService] Client Secret received!")
        print("🔑 [PaymentService] Payment Intent ID: \(extractPaymentIntentId(from: clientSecret) ?? "unknown")")
        
        return clientSecret
    }
    
    // Extraire Payment Intent ID du client secret
    func extractPaymentIntentId(from clientSecret: String) -> String? {
        // Format: "pi_3SZAPOFzjKYZqBoA1qT792EX_secret_..."
        // On veut: "pi_3SZAPOFzjKYZqBoA1qT792EX"
        
        print("🔍 [PaymentService] Extracting Payment Intent ID from: \(clientSecret)")
        
        let components = clientSecret.split(separator: "_secret_")
        guard let paymentIntentId = components.first else {
            print("❌ [PaymentService] Failed to extract Payment Intent ID")
            return nil
        }
        
        let extractedId = String(paymentIntentId)
        print("✅ [PaymentService] Extracted Payment Intent ID: \(extractedId)")
        
        return extractedId
    }
    
    //  Récupérer le dernier Payment Intent ID
    func getLastPaymentIntentId() -> String? {
        guard let clientSecret = lastClientSecret else {
            return nil
        }
        return extractPaymentIntentId(from: clientSecret)
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
        
        // Si Stripe, inclure obligatoirement le Payment Intent ID
        if paymentMethod == "stripe" {
            guard let paymentIntentId = paymentIntentId else {
                print("❌ [PaymentService] Payment Intent ID is required for Stripe payments")
                throw NetworkError.invalidRequest
            }
            body["paymentIntentId"] = paymentIntentId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📤 [PaymentService] Confirming purchase")
        print("   📦 Store Item: \(storeItemId)")
        print("   💳 Payment Method: \(paymentMethod)")
        if let piId = paymentIntentId {
            print("   🔑 Payment Intent ID: \(piId)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }
        
        print("📡 [PaymentService] Confirmation Status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 [PaymentService] Confirmation Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorStr = String(data: data, encoding: .utf8) ?? ""
            if errorStr.contains("Solde insuffisant") || errorStr.contains("insuffisant") {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Solde insuffisant"])
            }
            throw NetworkError.serverError
        }
        
        print("✅ [PaymentService] Purchase confirmed successfully")
        
        return try JSONDecoder().withISO8601().decode(Store.self, from: data)
    }
    
    //  Clear stored data
    func clearLastPayment() {
        lastClientSecret = nil
    }
}

//  Extension pour NetworkError
extension NetworkError {
    static let invalidRequest = NSError(
        domain: "PaymentService",
        code: -1001,
        userInfo: [NSLocalizedDescriptionKey: "Invalid payment request"]
    )
}
