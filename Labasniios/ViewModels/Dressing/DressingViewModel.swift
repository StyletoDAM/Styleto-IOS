import Foundation
import Combine

class DressingViewModel: ObservableObject {
    @Published var clothes: [Clothe] = []
    @Published var filteredClothes: [Clothe] = []
    @Published var selectedCategory: String = "Tous"
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchClothes()
    }
    
    func fetchClothes() {
        isLoading = true
        ClothesService.shared.fetchMyClothes { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let clothes):
                    self?.clothes = clothes
                    self?.filterByCategory()
                case .failure(let error):
                    print("Erreur: \(error)")
                }
            }
        }
    }
    
    func filterByCategory() {
        if selectedCategory == "Tous" {
            filteredClothes = clothes
        } else {
            filteredClothes = clothes.filter { $0.category!.lowercased() == selectedCategory.lowercased() }
        }
    }
    
    func selectCategory(_ category: String) {
        selectedCategory = category
        filterByCategory()
    }
}
