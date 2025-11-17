import Foundation
import Combine

class DressingViewModel: ObservableObject {
    @Published var clothes: [Clothe] = []
    @Published var filteredClothes: [Clothe] = []
    @Published var selectedCategory: String = "All"
    @Published var searchText: String = ""
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        fetchClothes()
    }
    
    // MARK: - Fetch
    func fetchClothes() {
        isLoading = true
        ClothesService.shared.fetchMyClothes { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let clothes):
                    self?.clothes = clothes
                    self?.filterClothes()
                case .failure(let error):
                    print("Erreur: \(error)")
                }
            }
        }
    }
    
    // MARK: - Setup Combine Bindings
    private func setupBindings() {
        Publishers.CombineLatest($selectedCategory, $searchText)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates(by: { $0.0 == $1.0 && $0.1 == $1.1 })
            .sink { [weak self] _ in
                self?.filterClothes()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Filtrage combiné (catégorie + recherche)
    private func filterClothes() {
        var result = clothes
        
        // Filtre par catégorie
        if selectedCategory != "All" {
            result = result.filter { $0.category?.lowercased() == selectedCategory.lowercased() }
        }
        
        // Filtre par recherche textuelle
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { clothe in
                let categoryMatch = clothe.category?.lowercased().contains(query) ?? false
                let colorMatch = clothe.color?.lowercased().contains(query) ?? false
                let styleMatch = clothe.style?.lowercased().contains(query) ?? false
                let seasonMatch = clothe.season?.lowercased().contains(query) ?? false
                
                return categoryMatch || colorMatch || styleMatch || seasonMatch
            }
        }
        
        filteredClothes = result
    }
    
    // MARK: - Sélection de catégorie
    func selectCategory(_ category: String) {
        selectedCategory = category
        searchText = ""
    }
    // MARK: - Suppression d'un vêtement
    func deleteClothe(_ clothe: Clothe, completion: ((Bool) -> Void)? = nil) {
        let id = clothe.id  // String non-optionnel

        ClothesService.shared.deleteClothe(id: id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.clothes.removeAll { $0.id == clothe.id }
                    self?.filterClothes()
                    completion?(true)
                case .failure:
                    completion?(false)
                }
            }
        }
    }
}
