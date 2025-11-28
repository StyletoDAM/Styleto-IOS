import Foundation
import Combine

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var currentPlan: SubscriptionPlan = .free
    @Published var usageStats: UsageStatsResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    static let shared = SubscriptionViewModel()   // ← Ajoute cette ligne
    private init() {}                             // ← Et rends l'init privé
    
    func loadSubscriptionData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let sub = SubscriptionService.shared.getMySubscription()
            async let stats = SubscriptionService.shared.getUsageStats()
            
            let (subscription, statsResult) = try await (sub, stats)
            self.currentPlan = subscription.plan
            self.usageStats = statsResult
        } catch {
            errorMessage = "Impossible de charger l'abonnement"
            print("Subscription load error:", error)
        }
        
        isLoading = false
    }
    
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
                await loadSubscriptionData() // refresh
            } else {
                errorMessage = result.message
            }
        } catch {
            errorMessage = "Échec du paiement. Vérifiez votre connexion."
        }
        
        isLoading = false
    }
}
