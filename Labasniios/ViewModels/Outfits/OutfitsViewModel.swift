//
//  OutfitsViewModel.swift
//  Labasniios
//
//  ViewModel pour l'écran Tenues (outfits)
//
//  Ce fichier gère la logique métier de l'écran Tenues :
//  - Récupération des tenues de l'utilisateur
//  - Génération de suggestions d'outfits par IA
//  - Acceptation et rejet de suggestions
//  - Suppression de tenues
//  - Gestion des erreurs et états de chargement
//
//  Architecture : MVVM avec ObservableObject (Combine)
//  Dépendances : Foundation, Combine, SwiftUI, OutfitsService
//

import Foundation
import Combine
import SwiftUI

/**
 * ViewModel pour l'écran Tenues (outfits)
 * 
 * Cette classe gère toute la logique métier de l'écran Tenues, où
 * l'utilisateur peut voir ses tenues créées et recevoir des suggestions
 * d'outfits générées par l'IA.
 * 
 * Fonctionnalités :
 * - Récupération des tenues depuis OutfitsService
 * - Génération de suggestions d'outfits par IA (basées sur le style)
 * - Acceptation de suggestions (création d'une nouvelle tenue)
 * - Rejet de suggestions
 * - Suppression de tenues existantes
 * - Gestion des erreurs spécifiques aux recommandations IA
 * - Gestion des états de chargement multiples (chargement, génération, acceptation)
 * 
 * Les suggestions IA peuvent prendre jusqu'à 2.5 minutes car elles
 * exécutent des scripts Python de machine learning côté serveur.
 * 
 * @see ObservableObject pour la réactivité avec SwiftUI
 * @see @MainActor pour l'exécution sur le thread principal
 * @see OutfitsService pour les opérations backend
 */
@MainActor
class OutfitsViewModel: ObservableObject {
    @Published var outfits: [Outfit] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var recommendationError: String? // ✨ NOUVEAU: Erreur spécifique pour les recommandations
    @Published var aiSuggestion: AIRecommendationResponse?
    @Published var isGenerating = false
    @Published var isAccepting = false
    @Published var successMessage: String?
    @Published var deletingIds: Set<String> = []
    
    private var cancellables = Set<AnyCancellable>()
    private let service = OutfitsService.shared
    
    func loadOutfits() {
        isLoading = true
        errorMessage = nil
        
        service.fetchMyOutfits()
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                }
            } receiveValue: { [weak self] outfits in
                print("📦 API → \(outfits.count) outfits reçus")
                self?.outfits = outfits.sorted {
                    ($0.createdAt ?? Date()) > ($1.createdAt ?? Date())
                }
            }
            .store(in: &cancellables)
    }
    
    // Génère seulement une SUGGESTION (ne crée PAS l'outfit)
    func generateAISuggestion(style: String) {
        isGenerating = true
        errorMessage = nil
        recommendationError = nil // ✨ NOUVEAU: Réinitialiser l'erreur de recommandation
        
        print("🎨 Demande de suggestion AI avec style: \(style)")
        
        service.getAIRecommendation(style: style)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isGenerating = false
                if case .failure(let error) = completion {
                    print("❌ Erreur génération AI:", error)
                    // ✨ NOUVEAU: Stocker l'erreur dans recommendationError pour afficher la carte d'erreur
                    self?.recommendationError = error.errorDescription
                }
            } receiveValue: { [weak self] response in
                print("✅ Suggestion AI reçue (pas encore créée)")
                self?.aiSuggestion = response
                self?.recommendationError = nil // ✨ NOUVEAU: Réinitialiser l'erreur en cas de succès
            }
            .store(in: &cancellables)
    }
    
    // ✅ ACCEPTER = Créer l'outfit + Mettre à jour feedback + Recharger la liste
    func acceptAISuggestion() {
        guard let suggestion = aiSuggestion else {
            print("⚠️ Aucune suggestion à accepter")
            return
        }
        
        isAccepting = true
        errorMessage = nil
        
        let clothesIds = suggestion.clothesIds
        let style = suggestion.metadata.preference
        
        print("✅ Acceptation de la suggestion → Création de l'outfit avec IDs:", clothesIds)
        print("🎨 Style choisi:", style)
        
        // 1️⃣ Créer l'outfit
        service.createOutfit(clothesIds: clothesIds, style: style)
            .flatMap { [weak self] response -> AnyPublisher<Void, NetworkError> in
                guard let self = self else {
                    return Fail(error: .serverError).eraseToAnyPublisher()
                }
                
                print("✅ Outfit créé, ID:", response.outfitId)
                
                // 2️⃣ Mettre à jour les compteurs acceptedCount
                print("📈 Mise à jour acceptedCount pour", clothesIds.count, "vêtements")
                return self.service.updateOutfitFeedback(clothesIds: clothesIds, accepted: true)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .failure(let error):
                    print("❌ Erreur:", error.errorDescription)
                    self.errorMessage = "Échec: \(error.errorDescription)"
                    self.isAccepting = false
                    
                case .finished:
                    print("✅✅ Outfit créé ET compteurs mis à jour")
                    self.reloadAfterAccept()
                }
            } receiveValue: { _ in
                print("✅ Feedback accepté enregistré")
            }
            .store(in: &cancellables)
    }
    
    // ✅ NOUVEAU : Recharger après acceptation
    private func reloadAfterAccept() {
        // Faire disparaître la suggestion immédiatement
        withAnimation(.easeInOut(duration: 0.3)) {
            self.aiSuggestion = nil
        }
        
        print("🔄 Rechargement de la liste des outfits...")
        
        // Recharger la liste complète depuis le serveur
        service.fetchMyOutfits()
            .sink { [weak self] completion in
                self?.isAccepting = false
                
                if case .failure(let error) = completion {
                    print("❌ Erreur rechargement:", error)
                    self?.errorMessage = "Outfit créé mais erreur de rechargement"
                }
            } receiveValue: { [weak self] outfits in
                print("🎉 Liste rechargée avec succès: \(outfits.count) outfits")
                self?.outfits = outfits.sorted {
                    ($0.createdAt ?? Date()) > ($1.createdAt ?? Date())
                }
            }
            .store(in: &cancellables)
    }
    
    // REJETER = Juste supprimer la suggestion, rien ne se crée
    // REJETER = Mettre à jour rejectedCount + Supprimer la suggestion
    func rejectAISuggestion() {
        guard let suggestion = aiSuggestion else {
            print("⚠️ Aucune suggestion à rejeter")
            return
        }
        
        let clothesIds = suggestion.clothesIds
        
        print("❌ Rejet de la suggestion → Mise à jour rejectedCount")
        
        // Mettre à jour les compteurs rejectedCount
        service.updateOutfitFeedback(clothesIds: clothesIds, accepted: false)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("❌ Erreur mise à jour feedback:", error)
                }
            } receiveValue: { [weak self] in
                print("✅ Feedback rejet enregistré")
                // Faire disparaître la suggestion
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.aiSuggestion = nil
                }
            }
            .store(in: &cancellables)
    }
    
    func updateOutfitStatus(_ outfit: Outfit, status: String) {
        service.updateOutfitStatus(outfit.id, status: status)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("❌ Erreur mise à jour status:", error)
                }
            } receiveValue: { }
            .store(in: &cancellables)
    }
    
    func deleteOutfit(_ outfit: Outfit) {
        // Empêcher les suppressions multiples simultanées
        guard !deletingIds.contains(outfit.id) else { return }
        
        deletingIds.insert(outfit.id)
        errorMessage = nil
        successMessage = nil // S'assurer que le message est nil avant de commencer
        
        service.deleteOutfit(outfit.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.deletingIds.remove(outfit.id)
                
                if case .failure(let error) = completion {
                    print("❌ Erreur suppression outfit:", error)
                    self.errorMessage = "Erreur lors de la suppression: \(error.errorDescription ?? "Erreur inconnue")"
                    self.successMessage = nil // S'assurer que successMessage reste nil en cas d'erreur
                }
            } receiveValue: { [weak self] in
                guard let self = self else { return }
                // Supprimer l'outfit de la liste
                withAnimation {
                    self.outfits.removeAll { $0.id == outfit.id }
                }
                // Afficher le message de succès seulement après la suppression réussie
                self.successMessage = "Tenue supprimée."
            }
            .store(in: &cancellables)
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
