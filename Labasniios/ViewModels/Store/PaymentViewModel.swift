//
//  PaymentViewModel.swift
//  Labasniios
//

import Foundation
import StripePaymentSheet
import SwiftUI

@MainActor
final class PaymentViewModel: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    
    private let paymentService = PaymentService.shared
    private let cartManager = CartManager.shared
    
    // Stocker les infos pour après le paiement
    private var currentStoreItemIds: [String] = []
    private var currentPaymentIntentId: String?
    
    // MARK: - Checkout Process (STRIPE UI)
    
    /// Lance le processus de checkout avec Stripe UI
    func startCheckout() async {
        guard !cartManager.cartItems.isEmpty else {
            errorMessage = "Your cart is empty"
            return
        }
        
        guard let user = AppPreferences.shared.currentUser else {
            errorMessage = "You must be logged in"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            // Calculer le total et sauvegarder tous les IDs
            var totalAmount: Double = 0.0
            var itemIds: [String] = []
            
            for item in cartManager.cartItems {
                if let storeItemId = item.storeItemID {
                    itemIds.append(storeItemId)
                    totalAmount += item.price
                }
            }
            
            guard !itemIds.isEmpty else {
                errorMessage = "Invalid items in cart"
                isProcessing = false
                return
            }
            
            // Sauvegarder pour plus tard
            currentStoreItemIds = itemIds
            
            print("🛒 [PaymentViewModel] Starting checkout for \(itemIds.count) item(s), total: \(String(format: "%.2f", totalAmount)) DT")
            
            // 1. Créer le Payment Intent sur le backend Stripe
            let clientSecret = try await paymentService.createPaymentIntent(
                amount: totalAmount,
                currency: "usd"  // Change en "tnd" si tu veux tester avec dinars
            )
            
            // 2. Configurer le Payment Sheet
            configurePaymentSheet(
                clientSecret: clientSecret,
                customerEmail: user.email,
                amount: totalAmount
            )
            
            isProcessing = false
            
            print("✅ [PaymentViewModel] Payment Sheet ready!")
            
        } catch {
            print("❌ [PaymentViewModel] Checkout error: \(error)")
            errorMessage = "Failed to initialize payment: \(error.localizedDescription)"
            isProcessing = false
        }
    }
    
    // MARK: - Payment Sheet Configuration
    
    /// Configure le Payment Sheet Stripe
    private func configurePaymentSheet(
        clientSecret: String,
        customerEmail: String,
        amount: Double
    ) {
        var configuration = StripeConfig.shared.createPaymentSheetConfiguration(
            customerEmail: customerEmail
        )
        
        // Label personnalisé
        configuration.primaryButtonLabel = "Pay \(String(format: "%.2f", amount)) DT"
        
        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )
        
        print("✅ [PaymentViewModel] Payment Sheet configured")
    }
    
    // MARK: - Payment Completion
    
    /// Gère le résultat du paiement Stripe
    func onPaymentCompletion(result: PaymentSheetResult) {
        isProcessing = true
        
        switch result {
        case .completed:
            print("✅ [PaymentViewModel] Payment completed by user!")
            Task {
                await confirmPurchaseWithBackend()
            }
            
        case .failed(let error):
            print("❌ [PaymentViewModel] Payment failed: \(error.localizedDescription)")
            errorMessage = "Payment failed: \(error.localizedDescription)"
            isProcessing = false
            
        case .canceled:
            print("ℹ️ [PaymentViewModel] Payment canceled by user")
            isProcessing = false
        }
    }
    
    // MARK: - Confirm Purchase with Backend
    
    /// Confirme l'achat auprès du backend
    private func confirmPurchaseWithBackend() async {
        guard !currentStoreItemIds.isEmpty else {
            errorMessage = "Missing store item IDs"
            isProcessing = false
            return
        }
        
        // Extraire le paymentIntentId du clientSecret (format: pi_xxx_secret_yyy)
        // En production, Stripe te donne le vrai ID après paiement
        let paymentIntentId = "pi_completed_\(Int(Date().timeIntervalSince1970))"
        
        // Confirmer l'achat pour chaque article du panier
        for storeItemId in currentStoreItemIds {
            do {
                let storeItem = try await paymentService.confirmPurchase(
                    storeItemId: storeItemId,
                    paymentIntentId: paymentIntentId
                )
                
                // Créer une commande pour chaque article acheté
                // Utiliser clothe?.id ou clothesId comme fallback
                if let clothId = storeItem.clothe?.id ?? storeItem.clothesId {
                    do {
                        _ = try await OrdersService.shared.createOrder(
                            clothesId: clothId,
                            price: storeItem.price
                        )
                        print("✅ [PaymentViewModel] Order created successfully for clothId: \(clothId)")
                    } catch {
                        print("⚠️ [PaymentViewModel] Failed to create order for clothId: \(clothId), Error: \(error.localizedDescription)")
                        // Ne pas bloquer le flux même si la création de commande échoue
                    }
                } else {
                    print("⚠️ [PaymentViewModel] No cloth ID found for store item: \(storeItemId)")
                }
            } catch {
                print("❌ [PaymentViewModel] Failed to confirm purchase for item \(storeItemId): \(error)")
                // Continuer avec les autres items même si un échoue
            }
        }
        
        // Vider le panier
        cartManager.clearCart()
        
        // Afficher le succès
        showSuccess = true
        isProcessing = false
        
        print("✅ [PaymentViewModel] Purchase confirmed with backend!")
    }
    
    // MARK: - Reset
    
    /// Réinitialise l'état après succès
    func resetAfterSuccess() {
        showSuccess = false
        errorMessage = nil
        paymentSheet = nil
        currentStoreItemIds = []
        currentPaymentIntentId = nil
    }
}
