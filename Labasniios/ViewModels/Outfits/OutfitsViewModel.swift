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
    func generateSuggestion() {
        isGenerating = true
        service.generateRandomOutfit()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isGenerating = false
                if case .failure(let error) = completion {
                    print("Erreur génération:", error)
                }
            } receiveValue: { [weak self] outfit in
                self?.suggestion = outfit
            }
            .store(in: &cancellables)
    }
    
    func acceptSuggestion() {
        guard let outfit = suggestion else { return }
        service.createOutfit(clothesIds: outfit.clothesIds.map { $0.id })
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("Erreur création outfit:", error)
                case .finished: break
                }
            } receiveValue: { [weak self] createdOutfit in
                self?.outfits.insert(createdOutfit, at: 0)
                self?.suggestion = nil
            }
            .store(in: &cancellables)
    }
    
    
    
    func rejectSuggestion() {
        guard let outfit = suggestion else { return }
        service.deleteOutfit(outfit.id)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { }
            .store(in: &cancellables)
        
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
