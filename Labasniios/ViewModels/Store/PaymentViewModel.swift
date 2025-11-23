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
    private var currentStoreItemId: String?
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
            // Pour l'instant, on traite uniquement le premier item
            let firstItem = cartManager.cartItems[0]
            
            guard let storeItemId = firstItem.storeItemID else {
                errorMessage = "Invalid item ID"
                isProcessing = false
                return
            }
            
            // Sauvegarder pour plus tard
            currentStoreItemId = storeItemId
            
            print("🛒 [PaymentViewModel] Starting checkout for \(String(format: "%.2f", firstItem.price)) DT")
            
            // 1. Créer le Payment Intent sur le backend Stripe
            let clientSecret = try await paymentService.createPaymentIntent(
                amount: firstItem.price,
                currency: "usd"  // Change en "tnd" si tu veux tester avec dinars
            )
            
            // 2. Configurer le Payment Sheet
            configurePaymentSheet(
                clientSecret: clientSecret,
                customerEmail: user.email,
                amount: firstItem.price
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
        guard let storeItemId = currentStoreItemId else {
            errorMessage = "Missing store item ID"
            isProcessing = false
            return
        }
        
        do {
            // Générer un payment intent ID
            // En production, Stripe te donne le vrai ID après paiement
            let paymentIntentId = "pi_completed_\(Int(Date().timeIntervalSince1970))"
            
            _ = try await paymentService.confirmPurchase(
                storeItemId: storeItemId,
                paymentIntentId: paymentIntentId
            )
            
            // Vider le panier
            cartManager.clearCart()
            
            // Afficher le succès
            showSuccess = true
            isProcessing = false
            
            print("✅ [PaymentViewModel] Purchase confirmed with backend!")
            
        } catch {
            print("❌ [PaymentViewModel] Backend confirmation error: \(error)")
            errorMessage = "Payment succeeded but confirmation failed. Please contact support."
            isProcessing = false
        }
    }
    
    // MARK: - Reset
    
    /// Réinitialise l'état après succès
    func resetAfterSuccess() {
        showSuccess = false
        errorMessage = nil
        paymentSheet = nil
        currentStoreItemId = nil
        currentPaymentIntentId = nil
    }
}
