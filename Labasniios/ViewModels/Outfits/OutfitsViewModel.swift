import Foundation
import Combine
import SwiftUI
 
@MainActor
class OutfitsViewModel: ObservableObject {
    @Published var outfits: [Outfit] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var aiSuggestion: AIRecommendationResponse?
    @Published var isGenerating = false
    @Published var isAccepting = false
    
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
        
        print("🎨 Demande de suggestion AI avec style: \(style)")
        
        service.getAIRecommendation(style: style)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isGenerating = false
                if case .failure(let error) = completion {
                    print("❌ Erreur génération AI:", error)
                    self?.errorMessage = error.errorDescription
                }
            } receiveValue: { [weak self] response in
                print("✅ Suggestion AI reçue (pas encore créée)")
                self?.aiSuggestion = response
            }
            .store(in: &cancellables)
    }
    
    // ✅ ACCEPTER = Créer l'outfit + Recharger la liste complète
    func acceptAISuggestion() {
        guard let suggestion = aiSuggestion else {
            print("⚠️ Aucune suggestion à accepter")
            return
        }
        
        isAccepting = true
        errorMessage = nil
        
        let clothesIds = suggestion.clothesIds
        let style = suggestion.metadata.preference  // ✅ Récupérer le style
        
        print("✅ Acceptation de la suggestion → Création de l'outfit avec IDs:", clothesIds)
        print("🎨 Style choisi:", style)
        
        service.createOutfit(clothesIds: clothesIds, style: style)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .failure(let error):
                    print("❌ Erreur création outfit:", error.errorDescription)
                    self.errorMessage = "Échec de la création: \(error.errorDescription)"
                    self.isAccepting = false
                    
                case .finished:
                    print("✅ Outfit créé avec succès dans la base")
                    // ✅ Recharger TOUTE la liste depuis le serveur
                    self.reloadAfterAccept()
                }
            } receiveValue: { [weak self] response in
                print("✅✅ Réponse création reçue, ID:", response.outfitId)
                // On ne fait rien ici, on attend le rechargement complet
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
    func rejectAISuggestion() {
        print("❌ Suggestion AI rejetée (aucune création)")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            aiSuggestion = nil
        }
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
        service.deleteOutfit(outfit.id)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("❌ Erreur suppression outfit:", error)
                }
            } receiveValue: { [weak self] in
                self?.outfits.removeAll { $0.id == outfit.id }
            }
            .store(in: &cancellables)
    }
}
