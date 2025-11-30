import Foundation
import Combine
import StripePaymentSheet
 
@MainActor
final class PaymentViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    @Published var paymentSheet: PaymentSheet?
    @Published var userBalance: Double = 0.0
    @Published var useBalance: Bool = false
    
    //  Stocker le Payment Intent ID après paiement réussi
    private var successfulPaymentIntentId: String?
    //  Stocker le client secret pour extraction ultérieure
    private var currentClientSecret: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let cartManager = CartManager.shared
    
    init() {
        NotificationCenter.default.publisher(for: .userDidUpdate)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshBalance()
                }
            }
            .store(in: &cancellables)
        
        Task {
            await refreshBalance()
        }
    }
    
    var canPayWithBalance: Bool {
        return userBalance >= cartManager.totalPrice
    }
    
    // MARK: - Refresh Balance
    func refreshBalance() async {
        guard let currentUser = AppPreferences.shared.currentUser else {
            print("⚠️ [PaymentViewModel] No user found")
            userBalance = 0.0
            return
        }
        
        do {
            let profileService = ProfileService()
            let freshUser = try await profileService.getProfile()
            userBalance = freshUser.balance ?? 0.0
            AppPreferences.shared.currentUser = freshUser
            print("✅ [PaymentViewModel] Balance refreshed: \(userBalance) TND")
        } catch {
            userBalance = currentUser.balance ?? 0.0
            print("⚠️ [PaymentViewModel] Using cached balance: \(userBalance) TND")
        }
    }
    
    // MARK: - Start Checkout
    func startCheckout() async {
        guard !cartManager.cartItems.isEmpty else {
            errorMessage = "Your cart is empty"
            return
        }
        
        await refreshBalance()
        
        isProcessing = true
        errorMessage = nil
        successfulPaymentIntentId = nil // Reset
        currentClientSecret = nil // Reset
        
        if useBalance {
            await purchaseWithBalance()
        } else {
            await initiateStripePayment()
        }
    }
    
    // MARK: - Purchase with Balance
    private func purchaseWithBalance() async {
        guard canPayWithBalance else {
            errorMessage = "Insufficient balance"
            isProcessing = false
            return
        }
        
        print("💰 [PaymentViewModel] Purchasing with balance")
        
        do {
            for item in cartManager.cartItems {
                let _ = try await PaymentService.shared.confirmPurchase(
                    storeItemId: item.storeItemID ?? "",
                    paymentMethod: "balance"
                )
            }
            
            await refreshBalance()
            cartManager.clearCart()
            showSuccess = true
            print("✅ [PaymentViewModel] Purchase completed with balance")
            
        } catch {
            print("❌ [PaymentViewModel] Balance purchase error: \(error)")
            if error.localizedDescription.contains("insuffisant") {
                errorMessage = "Insufficient balance. Please top up."
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isProcessing = false
    }
    
    // MARK: - Initiate Stripe Payment
    private func initiateStripePayment() async {
        let totalAmount = cartManager.totalPrice
        
        do {
            print("💳 [PaymentViewModel] Initiating Stripe payment for \(totalAmount) TND")
            
            let clientSecret = try await PaymentService.shared.createPaymentIntent(
                amount: totalAmount,
                currency: "usd"
            )
            
            //  Stocker le client secret AVANT de créer le PaymentSheet
            self.currentClientSecret = clientSecret
            
            // Extraire immédiatement le Payment Intent ID
            if let paymentIntentId = PaymentService.shared.extractPaymentIntentId(from: clientSecret) {
                self.successfulPaymentIntentId = paymentIntentId
                print("🔑 [PaymentViewModel] Pre-extracted Payment Intent ID: \(paymentIntentId)")
            }
            
            var config = StripeConfig.shared.createPaymentSheetConfiguration(
                customerEmail: AppPreferences.shared.currentUser?.email ?? ""
            )
            config.primaryButtonLabel = "Pay \(String(format: "%.2f", totalAmount)) TND"
            
            self.paymentSheet = PaymentSheet(
                paymentIntentClientSecret: clientSecret,
                configuration: config
            )
            
            print("✅ [PaymentViewModel] Payment Sheet ready")
            
        } catch {
            print("❌ [PaymentViewModel] Stripe init error: \(error)")
            errorMessage = "Payment initialization failed"
        }
        
        isProcessing = false
    }
    
    // MARK: - Payment Completion Handler
    func onPaymentCompletion(_ result: PaymentSheetResult) {
        isProcessing = true
        
        switch result {
        case .completed:
            print("✅ [PaymentViewModel] Stripe payment completed")
            
            // Le Payment Intent ID a déjà été extrait dans initiateStripePayment()
            if let paymentIntentId = successfulPaymentIntentId {
                print("🔑 [PaymentViewModel] Using Payment Intent ID: \(paymentIntentId)")
            } else {
                print("⚠️ [PaymentViewModel] Payment Intent ID not found - this should not happen!")
            }
            
            Task {
                await confirmStripeOrders()
            }
            
        case .failed(let error):
            print("❌ [PaymentViewModel] Payment failed: \(error)")
            errorMessage = "Payment failed: \(error.localizedDescription)"
            isProcessing = false
            
        case .canceled:
            print("ℹ️ [PaymentViewModel] Payment canceled")
            isProcessing = false
        }
    }
    
    //  Extraire Payment Intent ID du client secret
    private func extractPaymentIntentId() -> String? {
        // Cette fonction n'est plus nécessaire car on extrait l'ID immédiatement
        // dans initiateStripePayment()
        guard let clientSecret = currentClientSecret else { return nil }
        return PaymentService.shared.extractPaymentIntentId(from: clientSecret)
    }
    
    // MARK: - Confirm Stripe Orders
    private func confirmStripeOrders() async {
        
        guard let paymentIntentId = successfulPaymentIntentId else {
            print("❌ [PaymentViewModel] Missing Payment Intent ID - cannot confirm purchase")
            errorMessage = "Payment succeeded but missing transaction ID. Please contact support."
            isProcessing = false
            return
        }
        
        do {
            for item in cartManager.cartItems {
                //  Envoyer paymentMethod = "stripe" avec le Payment Intent ID
                let _ = try await PaymentService.shared.confirmPurchase(
                    storeItemId: item.storeItemID ?? "",
                    paymentMethod: "stripe",
                    paymentIntentId: paymentIntentId  
                )
            }
            
            await refreshBalance()
            cartManager.clearCart()
            showSuccess = true
            print("✅ [PaymentViewModel] Orders confirmed")
            
        } catch {
            print("❌ [PaymentViewModel] Order confirmation error: \(error)")
            errorMessage = "Payment succeeded but confirmation failed. Please contact support."
        }
        
        isProcessing = false
    }
    
    // MARK: - Reset After Success
    func resetAfterSuccess() {
        showSuccess = false
        paymentSheet = nil
        errorMessage = nil
        successfulPaymentIntentId = nil
        currentClientSecret = nil
    }
}
