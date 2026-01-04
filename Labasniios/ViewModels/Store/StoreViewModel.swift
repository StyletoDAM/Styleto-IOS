//
//  StoreViewModel.swift
//  Labasniios
//
//  ViewModel pour l'écran Store (marketplace)
//
//  Ce fichier gère la logique métier de l'écran Store :
//  - Récupération des articles du store (mes articles + découverte)
//  - Ajout de nouveaux articles à vendre
//  - Recherche et filtrage d'articles
//  - Suggestions de vente basées sur l'IA
//  - Gestion des quotas d'abonnement
//
//  Architecture : MVVM avec ObservableObject (Combine)
//  Dépendances : Foundation, Combine, SwiftUI, StoreService
//

import Foundation
import Combine
import SwiftUI

/**
 * ViewModel pour l'écran Store (marketplace)
 * 
 * Cette classe gère toute la logique métier de l'écran Store, où les
 * utilisateurs peuvent vendre et acheter des vêtements. Elle est marquée
 * @MainActor pour garantir que toutes les opérations se déroulent sur le
 * thread principal.
 * 
 * Fonctionnalités :
 * - Récupération des articles du store (mes articles + découverte)
 * - Ajout de nouveaux articles à vendre depuis la garde-robe
 * - Recherche textuelle en temps réel
 * - Suggestions de vente basées sur l'IA (vêtements peu utilisés)
 * - Gestion des quotas d'abonnement (affichage de paywalls)
 * - Gestion des tailles et conditions de produits
 * - Filtrage et tri des articles
 * 
 * Les suggestions de vente sont générées par l'IA pour identifier les
 * vêtements qui sont peu utilisés et pourraient être vendus.
 * 
 * @see ObservableObject pour la réactivité avec SwiftUI
 * @see @MainActor pour l'exécution sur le thread principal
 * @see StoreService pour les opérations backend
 */
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
    @Published var showUpgradeToPro = false
    @Published var selectedCondition: Store.ProductCondition = .new
    
    // ✨ NOUVEAU : Suggestions de vente
    @Published var sellSuggestions: [Clothe] = []
    @Published var currentSuggestion: Clothe?
    @Published var showSellSuggestion = false
    @Published var dismissedSuggestionIds: Set<String> = []
    
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
                self.loadDiscoverItems()
                self.loadSellSuggestions()  // ✨ NOUVEAU
            }
            .store(in: &cancellables)
    }
    
    // ✨ NOUVEAU : Charger les suggestions de vente
    func loadSellSuggestions() {
        print("📊 [StoreViewModel] Loading sell suggestions...")
        
        ClothesService.shared.fetchSellSuggestions()
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("❌ [StoreViewModel] Error loading suggestions: \(error)")
                }
            } receiveValue: { [weak self] suggestions in
                guard let self = self else { return }
                
                // Filtrer les suggestions déjà rejetées ou déjà dans le store
                let storeClothesIds = Set(self.storeItems.compactMap { $0.clothesId })
                let filtered = suggestions.filter { clothe in
                    !self.dismissedSuggestionIds.contains(clothe.id) &&
                    !storeClothesIds.contains(clothe.id)
                }
                
                print("✅ [StoreViewModel] Found \(filtered.count) sell suggestions")
                self.sellSuggestions = filtered
                
                // Afficher la première suggestion si disponible
                if let first = filtered.first, !self.showSellSuggestion {
                    self.showNextSuggestion()
                }
            }
            .store(in: &cancellables)
    }
    
    // ✨ NOUVEAU : Afficher la suggestion suivante
    func showNextSuggestion() {
        guard let next = sellSuggestions.first(where: { !dismissedSuggestionIds.contains($0.id) }) else {
            print("📊 [StoreViewModel] No more suggestions to show")
            currentSuggestion = nil
            showSellSuggestion = false
            return
        }
        
        print("📊 [StoreViewModel] Showing suggestion for: \(next.category ?? "unknown")")
        currentSuggestion = next
        showSellSuggestion = true
    }
    
    // ✨ NOUVEAU : Accepter la suggestion (préparer la vente)
    func acceptSellSuggestion() {
        guard let suggestion = currentSuggestion else { return }
        
        print("✅ [StoreViewModel] User accepted sell suggestion for: \(suggestion.id)")
        
        // Préparer le formulaire de vente
        selectedClothe = suggestion
        priceInput = ""
        sizeInput = ""
        selectedSize = "M"
        
        // Détection automatique chaussures
        let category = (suggestion.category ?? "").lowercased()
        isShoes = category.contains("shoe") ||
                  category.contains("sneaker") ||
                  category.contains("basket") ||
                  category.contains("boot") ||
                  category.contains("chaussure")
        
        // Reset taille selon type
        if isShoes {
            sizeInput = ""
        } else {
            selectedSize = "M"
        }
        
        // Fermer la suggestion IMMÉDIATEMENT
        withAnimation {
            showSellSuggestion = false
            currentSuggestion = nil
        }
        
        // Marquer comme traité
        dismissedSuggestionIds.insert(suggestion.id)
        
        // Ouvrir le sheet d'ajout APRÈS avoir fermé la suggestion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showAddToStore = true
        }
    }
    
    // ✨ NOUVEAU : Rejeter la suggestion
    func rejectSellSuggestion() {
        guard let suggestion = currentSuggestion else { return }
        
        print("❌ [StoreViewModel] User rejected sell suggestion for: \(suggestion.id)")
        
        // Marquer comme rejeté
        dismissedSuggestionIds.insert(suggestion.id)
        
        // Fermer et afficher la suivante
        showSellSuggestion = false
        currentSuggestion = nil
        
        // Afficher la suggestion suivante immédiatement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showNextSuggestion()
        }
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.showToast = false
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func loadMyClothes() {
        print("📦 [StoreViewModel] loadMyClothes() called")
        ClothesService.shared.fetchMyClothes { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let clothes):
                    print("✅ [StoreViewModel] Loaded \(clothes.count) clothes")
                    self.myClothes = clothes.filter { clothe in
                        !self.storeItems.contains { storeItem in
                            storeItem.clothesId == clothe.id
                        }
                    }
                    print("✅ [StoreViewModel] Filtered to \(self.myClothes.count) available clothes")
                case .failure(let error):
                    print("❌ [StoreViewModel] Error loading clothes: \(error.localizedDescription)")
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

        let finalSize: String = {
            if isShoes {
                return sizeInput.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                return selectedSize
            }
        }()

        guard !finalSize.isEmpty else {
            errorMessage = "Please select or enter a size"
            return
        }

        print("🔍 [StoreViewModel] Checking quota before adding item...")
        Task {
            do {
                let quotaCheck = try await SubscriptionService.shared.canSellItem()
                print("📊 [StoreViewModel] Quota check result: allowed=\(quotaCheck.allowed)")
                await MainActor.run {
                    if !quotaCheck.allowed {
                        print("⚠️ [StoreViewModel] Quota exceeded")
                        showUpgradeToPro = true
                        return
                    }
                    
                    print("✅ [StoreViewModel] Quota OK, proceeding")
                    proceedWithAddToStore(clothe: clothe, price: price, size: finalSize)
                }
            } catch {
                print("❌ [StoreViewModel] Error checking quota: \(error)")
                await MainActor.run {
                    errorMessage = "Error checking quota: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func proceedWithAddToStore(clothe: Clothe, price: Double, size: String) {
        isAdding = true

        let body: [String: Any] = [
            "clothesId": clothe.id,
            "price": price,
            "size": size,
            "condition": selectedCondition.rawValue
        ]

        StoreService.shared.createStoreItem(body: body)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isAdding = false
                if case .failure(let error) = completion {
                    let errorString = error.localizedDescription.lowercased()
                    if errorString.contains("limit") ||
                       errorString.contains("quota") ||
                       errorString.contains("exceeded") ||
                       errorString.contains("403") {
                        self.showUpgradeToPro = true
                    } else {
                        self.errorMessage = "Error: \(error.localizedDescription)"
                    }
                }
            } receiveValue: { [weak self] createdItem in
                guard let self = self else { return }

                self.selectedClothe = nil
                self.priceInput = ""
                self.sizeInput = ""
                self.selectedSize = "M"
                self.isShoes = false
                
                print("✅ [StoreViewModel] Item added successfully")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.showAddToStore = false
                    self.loadMyStore()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadDiscoverItems() {
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
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
        let status = item.status.rawValue.lowercased()
        let ownerName = item.user?.fullName.lowercased() ?? ""
        
        return category.contains(query) ||
               price.contains(query) ||
               status.contains(query) ||
               ownerName.contains(query)
    }
}
