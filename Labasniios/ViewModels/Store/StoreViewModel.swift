
import Foundation
import Combine

@MainActor
class StoreViewModel: ObservableObject {
    @Published var storeItems: [Store] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAddToStore = false
    @Published var myClothes: [Clothe] = []
    @Published var selectedClothe: Clothe?
    @Published var priceInput: String = ""
    @Published var isAdding = false
    @Published var showToast = false
    @Published var searchText: String = ""
    @Published var discoverItems: [Store] = []
    @Published private var rawStoreItems: [Store] = []
    @Published private var rawDiscoverItems: [Store] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let service = StoreService.shared
    
    // MARK: - Load My Store Items
    func loadMyStore() {
        isLoading = true
        errorMessage = nil
        
        StoreService.shared.fetchMyStore()
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] myItems in
                guard let self = self else { return }
                self.rawStoreItems = myItems
                self.storeItems = myItems  // ← Affiche tout au début
                self.loadDiscoverItems()
            }
            .store(in: &cancellables)
    }
    
    
    // MARK: - Update Store Item
    func updateStoreStatus(_ store: Store, status: String) {
        service.updateStore(store.id, status: status)
            .sink { _ in } receiveValue: { }
            .store(in: &cancellables)
    }
    
    // MARK: - Delete Store Item
    func deleteStoreItem(_ store: Store) {
        isLoading = true
        
        StoreService.shared.deleteStoreItem(store.id)
            .sink { [weak self] completion in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to delete: \(error.localizedDescription)"
                    }
                }
            } receiveValue: { [weak self] in
                DispatchQueue.main.async {
                    // Supprime de l'UI
                    self?.storeItems.removeAll { $0.id == store.id }
                    self?.discoverItems.removeAll { $0.id == store.id }
                    
                    // Toast
                    self?.showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.showToast = false
                    }
                }
            }
            .store(in: &cancellables)
    }
    func loadMyClothes() {
        ClothesService.shared.fetchMyClothes { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let clothes):
                    // Exclure les vêtements déjà en vente
                    self.myClothes = clothes.filter { clothe in
                        !self.storeItems.contains { $0.clothesId.id == clothe.id }
                    }
                case .failure(let error):
                    self.errorMessage = "Erreur chargement vêtements: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func addToStore(onSuccess: @escaping () -> Void) {
        guard let clothe = selectedClothe,
              let price = Double(priceInput), price >= 0 else {
            return
        }
        
        isAdding = true
        
        let body: [String: Any] = [
            "clothesId": clothe.id,
            "price": price,
            "status": "available"
        ]
        
        StoreService.shared.createStoreItem(body: body)
            .sink { completion in
                DispatchQueue.main.async {
                    // NE PAS mettre isAdding = false ici
                    if case .failure(let error) = completion {
                        self.isAdding = false  // ← Seulement en cas d'erreur
                        self.errorMessage = "Erreur: \(error.localizedDescription)"
                    }
                }
            } receiveValue: { [weak self] createdItem in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    // 1. Ajouter l'article
                    self.storeItems.insert(createdItem, at: 0)
                    
                    // 2. Réinitialiser
                    self.selectedClothe = nil
                    self.priceInput = ""
                    
                    // 3. Recharger les vêtements disponibles
                    self.loadMyClothes()
                    
                    // 4. METTRE isAdding = false AVANT onSuccess()
                    self.isAdding = false
                    
                    // 5. FERMER LE SHEET
                    onSuccess()
                }
            }
            .store(in: &cancellables)
    }
    func loadDiscoverItems() {
        guard !rawStoreItems.isEmpty else { return }
        
        StoreService.shared.fetchAllStoreItems()
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] allItems in
                guard let self = self else { return }
                let myIds = Set(self.rawStoreItems.map { $0.id })
                let filtered = allItems.filter { !myIds.contains($0.id) }
                self.rawDiscoverItems = filtered
                self.discoverItems = filtered
                self.filterItems() // ← Applique le filtre actuel
            }
            .store(in: &cancellables)
    }
    func updateStorePrice(_ storeId: String, price: Double) {
        isLoading = true
        StoreService.shared.updateStorePrice(storeId, price: price)
            .sink { [weak self] completion in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if case .failure = completion {
                        self?.errorMessage = "Échec de la mise à jour"
                    }
                }
            } receiveValue: { [weak self] updatedStore in
                DispatchQueue.main.async {
                    if let index = self?.storeItems.firstIndex(where: { $0.id == updatedStore.id }) {
                        self?.storeItems[index] = updatedStore
                    }
                    if let index = self?.discoverItems.firstIndex(where: { $0.id == updatedStore.id }) {
                        self?.discoverItems[index] = updatedStore
                    }
                    self?.showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.showToast = false
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func markAsSold(_ storeId: String) {
        isLoading = true
        StoreService.shared.markAsSold(storeId)
            .sink { [weak self] completion in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if case .failure = completion {
                        self?.errorMessage = "Échec"
                    }
                }
            } receiveValue: { [weak self] updatedStore in
                DispatchQueue.main.async {
                    if let index = self?.storeItems.firstIndex(where: { $0.id == updatedStore.id }) {
                        self?.storeItems[index] = updatedStore
                    }
                    self?.showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.showToast = false
                    }
                }
            }
            .store(in: &cancellables)
    }
    init() {
        setupSearchBinding()
    }
    
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.filterItems()
            }
            .store(in: &cancellables)
    }
    
    // Appelé à chaque changement de searchText
    private func filterItems() {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        
        if query.isEmpty {
            storeItems = rawStoreItems
            discoverItems = rawDiscoverItems
            return
        }
        
        let filteredMy = rawStoreItems.filter { matchesSearch($0, query: query) }
        let filteredDiscover = rawDiscoverItems.filter { matchesSearch($0, query: query) }
        
        storeItems = filteredMy
        discoverItems = filteredDiscover
    }
    
    private func matchesSearch(_ item: Store, query: String) -> Bool {
        let category = item.clothesId.category?.lowercased() ?? ""
        let price = "\(item.price)"
        let status = item.status.lowercased()
        let ownerName = item.userId.fullName?.lowercased() ?? ""
        
        return category.contains(query) ||
        price.contains(query) ||
        status.contains(query) ||
        ownerName.contains(query)
    }
}
