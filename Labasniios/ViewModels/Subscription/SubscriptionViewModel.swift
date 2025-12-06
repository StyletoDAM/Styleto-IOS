// ViewModels/Subscription/SubscriptionViewModel.swift
import Foundation
import Combine

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var currentPlan: SubscriptionPlan = .free
    @Published var usageStats: UsageStatsResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isCanceling = false
    @Published var subscription: SubscriptionResponse?
    
    static let shared = SubscriptionViewModel()
    private init() {}
    
    func loadSubscriptionData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let sub = SubscriptionService.shared.getMySubscription()
            async let stats = SubscriptionService.shared.getUsageStats()
            
            let (subscription, statsResult) = try await (sub, stats)
            self.currentPlan = subscription.plan
            self.usageStats = statsResult
            self.subscription = subscription
            
            print("✅ [SubscriptionVM] Loaded: \(subscription.plan.rawValue)")
        } catch {
            errorMessage = "Impossible de charger l'abonnement"
            print("❌ [SubscriptionVM] Load error: \(error)")
        }
        
        isLoading = false
    }
    
    // ✨ NOUVEAU: Annuler l'abonnement
    func cancelSubscription() async {
        isCanceling = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let result = try await SubscriptionService.shared.cancelSubscription()
            
            if result.success {
                successMessage = result.message
                
                // Rafraîchir les données
                await loadSubscriptionData()
                
                print("✅ [SubscriptionVM] Subscription canceled successfully")
                print("   Expires at: \(result.expiresAt?.formatted() ?? "unknown")")
            } else {
                errorMessage = result.message
            }
        } catch NetworkError.serverMessage(let message) {
            errorMessage = message
            print("❌ [SubscriptionVM] Cancel error: \(message)")
        } catch {
            errorMessage = "Failed to cancel subscription. Please try again."
            print("❌ [SubscriptionVM] Cancel error: \(error)")
        }
        
        isCanceling = false
    }
    
    // ANCIEN: Achat de plan (conservé pour compatibilité)
    func purchasePlan(_ plan: SubscriptionPlan) async {
        isLoading = true
        successMessage = nil
        errorMessage = nil
        
        let payment = PurchaseSimulationRequest(
            cardNumber: "4242 4242 4242 4242",
            expiryDate: "12/28",
            cvv: "123",
            cardholderName: "Test User"
        )
        
        do {
            let result = try await SubscriptionService.shared.purchasePlan(plan, paymentData: payment)
            if result.success {
                successMessage = result.message
                await loadSubscriptionData()
            } else {
                errorMessage = result.message
            }
        } catch {
            errorMessage = "Échec du paiement. Vérifiez votre connexion."
        }
        
        isLoading = false
    }
    
    // ✨ NOUVEAU: Vérifier si l'abonnement peut être annulé
    var canCancelSubscription: Bool {
        // On peut annuler si on a un plan payant (PREMIUM ou PRO_SELLER)
        return currentPlan == .premium || currentPlan == .proSeller
    }
    
    // ✨ NOUVEAU: Message pour expiration
    var expirationMessage: String? {
        guard let expiresAt = subscription?.expiresAt else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return "Your subscription will expire on \(formatter.string(from: expiresAt))"
    }
}
