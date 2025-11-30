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
    
    private var cancellables = Set<AnyCancellable>()
    private let cartManager = CartManager.shared
    
    init() {
        // ✅ Observer les changements d'utilisateur
        NotificationCenter.default.publisher(for: .userDidUpdate)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshBalance()
                }
            }
            .store(in: &cancellables)
        
        // ✅ Charger le balance au démarrage
        Task {
            await refreshBalance()
        }
    }
    
    var canPayWithBalance: Bool {
        return userBalance >= cartManager.totalPrice
    }
    
    // MARK: - ✅ Refresh Balance (PUBLIC pour CartView)
    func refreshBalance() async {
        guard let currentUser = AppPreferences.shared.currentUser else {
            print("⚠️ [PaymentViewModel] No user found")
            userBalance = 0.0
            return
        }
        
        // Récupérer le profil frais du serveur
        do {
            let profileService = ProfileService()
            let freshUser = try await profileService.getProfile()
            userBalance = freshUser.balance ?? 0.0
            
            // Mettre à jour AppPreferences
            AppPreferences.shared.currentUser = freshUser
            
            print("✅ [PaymentViewModel] Balance refreshed: \(userBalance) TND")
        } catch {
            // Fallback sur le cache local
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
        
        // ✅ Rafraîchir le balance avant de procéder
        await refreshBalance()
        
        isProcessing = true
        errorMessage = nil
        
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
            // Acheter chaque article avec le balance
            for item in cartManager.cartItems {
                let _ = try await PaymentService.shared.confirmPurchase(
                    storeItemId: item.storeItemID ?? "",
                    paymentMethod: "balance"
                )
            }
            
            // ✅ Rafraîchir le balance après achat
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
    
    // MARK: - Confirm Stripe Orders
    private func confirmStripeOrders() async {
        do {
            for item in cartManager.cartItems {
                let _ = try await PaymentService.shared.confirmPurchase(
                    storeItemId: item.storeItemID ?? "",
                    paymentMethod: "card"
                )
            }
            
            // ✅ Rafraîchir le balance (même si payé par carte, pour sync)
            await refreshBalance()
            
            cartManager.clearCart()
            showSuccess = true
            print("✅ [PaymentViewModel] Orders confirmed")
            
        } catch {
            print("❌ [PaymentViewModel] Order confirmation error: \(error)")
            errorMessage = "Payment succeeded but confirmation failed"
        }
        
        isProcessing = false
    }
    
    // MARK: - Reset After Success
    func resetAfterSuccess() {
        showSuccess = false
        paymentSheet = nil
        errorMessage = nil
    }
}
