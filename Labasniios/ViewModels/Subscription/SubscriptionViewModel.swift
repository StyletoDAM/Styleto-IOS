//
//  SubscriptionViewModel.swift
//  Labasniios
//
//  ViewModel pour la gestion des abonnements
//
//  Ce fichier gère la logique métier de la gestion des abonnements :
//  - Chargement des informations d'abonnement
//  - Récupération des statistiques d'utilisation
//  - Mise à jour d'abonnement
//  - Annulation d'abonnement
//  - Gestion des sessions Stripe Checkout
//
//  Architecture : MVVM avec ObservableObject (Combine) + Singleton
//  Dépendances : Foundation, Combine, SubscriptionService
//

import Foundation
import Combine

/**
 * ViewModel pour la gestion des abonnements
 * 
 * Cette classe gère toute la logique métier de la gestion des abonnements.
 * Elle implémente le pattern Singleton pour permettre un accès global depuis
 * n'importe où dans l'application. Elle est marquée @MainActor pour garantir
 * que toutes les opérations se déroulent sur le thread principal.
 * 
 * Fonctionnalités :
 * - Chargement des informations d'abonnement (plan, statut, dates)
 * - Récupération des statistiques d'utilisation (quotas utilisés/restants)
 * - Mise à jour d'abonnement (upgrade/downgrade)
 * - Annulation d'abonnement avec refresh automatique
 * - Gestion des sessions Stripe Checkout pour les nouveaux abonnements
 * - Détection des états d'abonnement (active, canceled, expired)
 * 
 * Les statistiques d'utilisation incluent :
 * - Détection de vêtements (clothes detection)
 * - Génération d'outfits (outfit suggestions)
 * - Vente dans le store (store selling)
 * 
 * @see ObservableObject pour la réactivité avec SwiftUI
 * @see @MainActor pour l'exécution sur le thread principal
 * @see SubscriptionService pour les opérations backend
 */
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
            print("   📊 Status: \(subscription.status)")
            print("   📊 Clothes Detection: \(statsResult.clothesDetection.used)")
            print("   📊 Outfit Suggestions: \(statsResult.outfitSuggestions.used)")
            print("   📊 Store Selling: \(statsResult.storeSelling.used)")
        } catch {
            errorMessage = "Unable to load subscription"
            print("❌ [SubscriptionVM] Load error: \(error)")
        }
        
        isLoading = false
    }
    
    // ✨ NOUVEAU: Annuler l'abonnement avec refresh automatique
    func cancelSubscription() async {
        isCanceling = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let result = try await SubscriptionService.shared.cancelSubscription()
            
            if result.success {
                successMessage = result.message
                
                print("✅ [SubscriptionVM] Subscription canceled successfully")
                print("   ⏰ Will expire: \(result.expiresAt?.formatted() ?? "unknown")")
                
                // ✨ STRATÉGIE SIMPLE: Rafraîchir immédiatement après le succès
                // Le backend a déjà mis à jour le statut à "canceled"
                await loadSubscriptionData()
                
                print("🔄 [SubscriptionVM] Data refreshed - Status should now be 'canceled'")
                print("   📊 Current status: \(subscription?.status ?? "unknown")")
                print("   📊 isCanceled computed property: \(isCanceled)")
                
                // ✨ NOUVEAU: Notifier les autres vues (Settings, etc.)
                NotificationCenter.default.post(name: .subscriptionDidUpdate, object: nil)
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
                
                // ✨ NOUVEAU: Notifier les autres vues
                NotificationCenter.default.post(name: .subscriptionDidUpdate, object: nil)
            } else {
                errorMessage = result.message
            }
        } catch {
            errorMessage = "Payment failed. Please check your connection."
        }
        
        isLoading = false
    }
    
    // ✨ NOUVEAU: Vérifier si l'abonnement peut être annulé
    var canCancelSubscription: Bool {
        // On peut annuler SEULEMENT si:
        // 1. On a un plan payant (PREMIUM ou PRO_SELLER)
        // 2. ET le statut n'est PAS déjà "canceled"
        let hasPaidPlan = currentPlan == .premium || currentPlan == .proSeller
        let notAlreadyCanceled = subscription?.status != "canceled"
        
        return hasPaidPlan && notAlreadyCanceled
    }
    
    // ✨ NOUVEAU: Vérifier si l'abonnement est annulé
    var isCanceled: Bool {
        return subscription?.status == "canceled"
    }
    
    // ✨ NOUVEAU: Message pour expiration
    var expirationMessage: String? {
        guard let expiresAt = subscription?.expiresAt else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        if isCanceled {
            return "Access expires on \(formatter.string(from: expiresAt))"
        } else {
            return "Renews on \(formatter.string(from: expiresAt))"
        }
    }
    
    // ✨ NOUVEAU: Date d'expiration formatée
    var expirationDate: String {
        guard let expiresAt = subscription?.expiresAt else {
            return "unknown date"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: expiresAt)
    }
    
    // ✨ NOUVEAU: Forcer un refresh manuel des stats
    func refreshUsageStats() async {
        do {
            let stats = try await SubscriptionService.shared.getUsageStats()
            self.usageStats = stats
            
            print("🔄 [SubscriptionVM] Stats refreshed")
            print("   📊 Clothes Detection: \(stats.clothesDetection.used)")
            print("   📊 Outfit Suggestions: \(stats.outfitSuggestions.used)")
            print("   📊 Store Selling: \(stats.storeSelling.used)")
        } catch {
            print("❌ [SubscriptionVM] Failed to refresh stats: \(error)")
        }
    }
}
