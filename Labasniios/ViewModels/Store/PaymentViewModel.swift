import Foundation
import StripePaymentSheet
import Combine

@MainActor
final class PaymentViewModel: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    @Published var useBalance = true
    
    @Published var userBalance: Double = 0.0
    
    private let paymentService = PaymentService.shared
    private let cartManager = CartManager.shared
    
    private var currentStoreItemIds: [String] = []
    private var lastClientSecret: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    var totalPrice: Double { cartManager.totalPrice }
    var canPayWithBalance: Bool { userBalance >= totalPrice }
    
    init() {
        userBalance = AppPreferences.shared.currentUser?.balance ?? 0.0
        
        // Écouter les mises à jour du profil utilisateur
        NotificationCenter.default.publisher(for: .userDidUpdate)
            .compactMap { $0.object as? User }
            .sink { [weak self] updatedUser in
                self?.userBalance = updatedUser.balance ?? 0.0
                print("💰 [PaymentViewModel] Balance mise à jour: \(updatedUser.balance ?? 0.0) TND")
            }
            .store(in: &cancellables)
        
        // Écouter les changements directs de AppPreferences
        AppPreferences.shared.$currentUser
            .compactMap { $0?.balance }
            .sink { [weak self] balance in
                self?.userBalance = balance
                print("💰 [PaymentViewModel] Balance actualisée: \(balance) TND")
            }
            .store(in: &cancellables)
    }
    
    func startCheckout() async {
        guard !cartManager.cartItems.isEmpty else {
            errorMessage = "Panier vide"
            return
        }
        
        currentStoreItemIds = cartManager.cartItems.compactMap { $0.storeItemID }
        isProcessing = true
        errorMessage = nil
        
        // PAIEMENT PAR BALANCE
        if useBalance && canPayWithBalance {
            await confirmWithBalance()
            return
        }
        
        // SINON : Stripe classique
        do {
            let clientSecret = try await paymentService.createPaymentIntent(amount: totalPrice)
            lastClientSecret = clientSecret
            
            var configuration = StripeConfig.shared.createPaymentSheetConfiguration(
                customerEmail: AppPreferences.shared.currentUser?.email ?? ""
            )
            configuration.primaryButtonLabel = "Payer \(String(format: "%.2f", totalPrice)) DT"
            
            paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
            isProcessing = false
        } catch {
            errorMessage = "Erreur paiement : \(error.localizedDescription)"
            isProcessing = false
        }
    }
    
    private func confirmWithBalance() async {
        await confirmPurchases(paymentMethod: "balance", paymentIntentId: nil)
    }
    
    func onPaymentCompletion(result: PaymentSheetResult) {
        isProcessing = true
        
        if case .completed = result {
            let paymentIntentId = lastClientSecret.components(separatedBy: "_secret_").first!
            Task {
                await confirmPurchases(paymentMethod: "stripe", paymentIntentId: paymentIntentId)
            }
        } else if case .failed(let error) = result {
            errorMessage = error.localizedDescription
            isProcessing = false
        } else {
            isProcessing = false
        }
    }
    
    private func confirmPurchases(paymentMethod: String, paymentIntentId: String?) async {
        for storeItemId in currentStoreItemIds {
            do {
                _ = try await paymentService.confirmPurchase(
                    storeItemId: storeItemId,
                    paymentMethod: paymentMethod,
                    paymentIntentId: paymentIntentId
                )
            } catch {
                print("Erreur confirmation item \(storeItemId): \(error)")
                // on continue quand même les autres
            }
        }
        
        cartManager.clearCart()
        
        // ✅ Rafraîchir la balance après achat
        await AppPreferences.shared.refreshUserProfile()
        
        showSuccess = true
        isProcessing = false
    }
    
    func resetAfterSuccess() {
        showSuccess = false
        errorMessage = nil
        paymentSheet = nil
        currentStoreItemIds = []
    }
}
