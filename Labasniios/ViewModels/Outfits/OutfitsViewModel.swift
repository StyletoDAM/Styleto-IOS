// ViewModels/Outfits/OutfitsViewModel.swift
import Foundation
import Combine

@MainActor
class OutfitsViewModel: ObservableObject {
    @Published var outfits: [Outfit] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var suggestion: Outfit?
    @Published var isGenerating = false
    

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
                print("API → \(outfits.count) outfits reçus")
                self?.outfits = outfits.sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date()
                }
            }
            .store(in: &cancellables)
    }
    func generateOutfit() {
        print("GENERATE OUTFIT CALLED")
        isGenerating = true
        
        OutfitsService.shared.generateRandomOutfit()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isGenerating = false
                    if case .failure(let error) = completion {
                        print("ERREUR GÉNÉRATION:", error)
                    }
                },
                receiveValue: { [weak self] outfit in
                    print("SUGGESTION REÇUE:", outfit.id)
                    self?.suggestion = outfit  // ICI : suggestion, PAS outfits
                    // NE FAIS PAS : self?.outfits.append(outfit)
                }
            )
            .store(in: &cancellables)
    }

    func acceptSuggestion(_ outfit: Outfit) {
        // Ajoute dans la liste
        outfits.insert(outfit, at: 0)
        
        // Appelle l'API
        updateOutfitStatus(outfit, status: "accepted")
        
        // Supprime la suggestion
        suggestion = nil
    }

    func rejectSuggestion(_ outfit: Outfit) {
        deleteOutfit(outfit)
        suggestion = nil
    }

    func updateOutfitStatus(_ outfit: Outfit, status: String) {
        OutfitsService.shared.updateOutfitStatus(outfit.id, status: status)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { }
            .store(in: &cancellables)
    }

    func deleteOutfit(_ outfit: Outfit) {
        OutfitsService.shared.deleteOutfit(outfit.id)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] in
                self?.suggestion = nil
            }
            .store(in: &cancellables)
    }

    
    

    
}
