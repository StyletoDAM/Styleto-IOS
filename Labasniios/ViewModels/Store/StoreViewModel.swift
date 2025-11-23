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
    @Published var sizeInput: String = ""
    @Published var selectedSize: String = "M"
    @Published var isShoes: Bool = false
    
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
            }
            receiveValue: { [weak self] myItems in
                guard let self = self else { return }
                self.rawStoreItems = myItems
                self.storeItems = myItems
                self.loadDiscoverItems()  // ← Déjà appelé automatiquement ici !
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
                    self?.storeItems.removeAll { $0.id == store.id }
                    self?.discoverItems.removeAll { $0.id == store.id }
                    
                    self?.showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in  // ✅ CORRIGÉ
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
                    self.myClothes = clothes.filter { clothe in
                        !self.storeItems.contains { storeItem in
                            storeItem.clothesId == clothe.id
                        }
                    }
                case .failure(let error):
                    self.errorMessage = "Erreur chargement vêtements: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func addToStore() {
        guard let clothe = selectedClothe,
              let price = Double(priceInput), price >= 0 else {
            return
        }

        isAdding = true

        let finalSize: String = {
            if isShoes {
                return sizeInput.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                return selectedSize
            }
        }()

        guard !finalSize.isEmpty else {
            isAdding = false
            errorMessage = "Please select or enter a size"
            return
        }

        let body: [String: Any] = [
            "clothesId": clothe.id,
            "price": price,
            "size": finalSize
        ]

        StoreService.shared.createStoreItem(body: body)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isAdding = false
                if case .failure(let error) = completion {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] createdItem in
                guard let self = self else { return }

                self.selectedClothe = nil
                self.priceInput = ""
                self.sizeInput = ""
                self.selectedSize = "M"
                self.isShoes = false
                self.showAddToStore = false

                self.loadMyStore()
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
                self.filterItems()
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in  // ✅ CORRIGÉ
                        self?.showToast = false
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func updateStoreSize(_ storeId: String, newSize: String) {
        isLoading = true
        
        StoreService.shared.updateStoreSize(storeId, size: newSize)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Échec mise à jour taille"
                    print("ERREUR:", error)
                }
            } receiveValue: { [weak self] updatedStore in
                if let index = self?.storeItems.firstIndex(where: { $0.id == updatedStore.id }) {
                    self?.storeItems[index] = updatedStore
                }
                if let index = self?.discoverItems.firstIndex(where: { $0.id == updatedStore.id }) {
                    self?.discoverItems[index] = updatedStore
                }
                self?.showToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in  // ✅ CORRIGÉ
                    self?.showToast = false
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in  // ✅ CORRIGÉ
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
        let category = item.clothe?.category?.lowercased() ?? ""
        let price = "\(item.price)"
        let status = item.status.rawValue.lowercased()  // ✅ CORRIGÉ
        let ownerName = item.user?.fullName.lowercased() ?? ""  // ✅ CORRIGÉ
        
        return category.contains(query) ||
               price.contains(query) ||
               status.contains(query) ||
               ownerName.contains(query)
    }
}
