//
//  CartService.swift
//  Labasniios
//
//  Service pour la gestion du panier d'achat
//
//  Ce fichier gère toutes les opérations liées au panier d'achat :
//  - Récupération du panier depuis le backend
//  - Ajout et suppression d'articles
//  - Synchronisation avec le serveur
//  - Gestion du cache local
//
//  Architecture : Singleton avec ObservableObject (Combine)
//  Dépendances : Foundation, Combine, CartAPIService
//

import Foundation
import Combine

/**
 * Gestionnaire de panier d'achat
 * 
 * Cette classe gère le panier d'achat de l'utilisateur en utilisant
 * l'API backend au lieu de CoreData. Elle est marquée @MainActor pour
 * garantir que toutes les opérations se déroulent sur le thread principal.
 * 
 * Fonctionnalités :
 * - Synchronisation automatique avec le serveur
 * - Cache local pour les performances
 * - Observation des changements d'utilisateur
 * - Gestion automatique du logout (vidage du panier)
 * 
 * @see ObservableObject pour la réactivité avec SwiftUI
 * @see @MainActor pour l'exécution sur le thread principal
 * @see CartAPIService pour les appels API backend
 */
@MainActor
class CartManager: ObservableObject {
    static let shared = CartManager()
    
    @Published var cartItems: [CartItemModel] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let cartAPIService = CartAPIService.shared
    
    // Cache de l'ID utilisateur pour éviter les accès répétés
    private var cachedUserId: String?
    
    private init() {
        // Charger l'userId et le panier au démarrage
        loadUserIdAndFetchCart()
        
        // Observer les changements d'utilisateur
        NotificationCenter.default.publisher(for: .userDidUpdate)
            .sink { [weak self] notification in
                Task { @MainActor in
                    self?.cachedUserId = AppPreferences.shared.currentUser?.id
                    await self?.fetchCartItems()
                    print("🔄 [CartManager] Utilisateur mis à jour, panier rechargé")
                }
            }
            .store(in: &cancellables)
        
        // Observer le logout
        NotificationCenter.default.publisher(for: .didRequestNavigateToLogin)
            .sink { [weak self] _ in
                self?.cachedUserId = nil
                self?.handleLogout()
            }
            .store(in: &cancellables)
    }
    
    /// Charge l'userId et le panier de manière synchrone
    private func loadUserIdAndFetchCart() {
        Task { @MainActor in
            self.cachedUserId = AppPreferences.shared.currentUser?.id
            
            if let userId = self.cachedUserId {
                print("✅ [CartManager] Utilisateur chargé: \(userId)")
            } else {
                print("⚠️ [CartManager] Aucun utilisateur connecté au démarrage")
            }
            
            // Charger le panier après avoir récupéré l'userId
            await self.fetchCartItems()
        }
    }
    
    /// ✨ MODIFIÉ : Récupère les articles du panier depuis l'API
    func fetchCartItems() async {
        guard let userId = cachedUserId else {
            print("⚠️ [CartManager] Aucun utilisateur connecté – panier vide")
            self.cartItems = []
            return
        }
        
        guard TokenManager.shared.getToken() != nil else {
            print("⚠️ [CartManager] Pas de token – panier vide")
            self.cartItems = []
            return
        }
        
        do {
            let cartResponse = try await cartAPIService.getCart()
            
            // Convertir les réponses API en modèles locaux
            let items = cartResponse.items.compactMap { itemResponse -> CartItemModel? in
                guard let storeItem = itemResponse.storeItem else { return nil }
                let clothes = storeItem.clothesId
                
                // Extraire le titre depuis category ou style
                let categoryName = extractCategory(clothes?.category)
                let title = (clothes?.style?.isEmpty == false ? clothes?.style : categoryName)?
                    .capitalized ?? "Item"
                
                return CartItemModel(
                    id: itemResponse.storeItemId,
                    userId: userId,
                    storeItemID: itemResponse.storeItemId,
                    title: title,
                    size: storeItem.size,
                    price: storeItem.price,
                    imageURL: clothes?.imageURL,
                    addedAt: itemResponse.addedAt,
                    status: storeItem.status // ✨ NOUVEAU : Statut "available" | "sold"
                )
            }
            
            self.cartItems = items
            print("✅ [CartManager] \(items.count) articles chargés depuis l'API")
            
        } catch {
            print("❌ [CartManager] Erreur fetch panier: \(error)")
            self.cartItems = []
        }
    }
    
    /// ✨ MODIFIÉ : Ajoute un article au panier via l'API
    func addToCart(storeItem: Store) {
        guard let userId = cachedUserId else {
            print("⚠️ [CartManager] Impossible d'ajouter : utilisateur non connecté")
            
            // Tentative de récupération depuis AppPreferences
            Task { @MainActor in
                if let currentUser = AppPreferences.shared.currentUser {
                    print("   ℹ️ Utilisateur trouvé dans AppPreferences : \(currentUser.id)")
                    self.cachedUserId = currentUser.id
                    self.addToCart(storeItem: storeItem)
                } else {
                    print("   ❌ Aucun utilisateur dans AppPreferences")
                }
            }
            return
        }
        
        Task { @MainActor in
            do {
                let _ = try await cartAPIService.addToCart(storeItemId: storeItem.id)
                await fetchCartItems()
                print("✅ [CartManager] Article ajouté au panier")
            } catch {
                print("❌ [CartManager] Erreur ajout panier: \(error)")
            }
        }
    }
    
    /// ✨ MODIFIÉ : Supprime un article du panier via l'API
    func removeFromCart(_ cartItem: CartItemModel) {
        Task { @MainActor in
            do {
                let _ = try await cartAPIService.removeFromCart(storeItemId: cartItem.storeItemID)
                await fetchCartItems()
                print("🗑️ [CartManager] Article supprimé du panier")
            } catch {
                print("❌ [CartManager] Erreur suppression panier: \(error)")
            }
        }
    }
    
    /// ✨ MODIFIÉ : Vide tout le panier via l'API
    func clearCart() {
        guard let userId = cachedUserId else {
            print("⚠️ [CartManager] Impossible de vider le panier : utilisateur non connecté")
            return
        }
        
        Task { @MainActor in
            do {
                try await cartAPIService.clearCart()
                await fetchCartItems()
                print("🗑️ [CartManager] Panier vidé pour l'utilisateur \(userId)")
            } catch {
                print("❌ [CartManager] Erreur vidage panier: \(error)")
            }
        }
    }
    
    /// ✨ MODIFIÉ : Prix total du panier (seulement les items disponibles)
    var totalPrice: Double {
        cartItems
            .filter { $0.status == "available" } // ✨ Seulement les items disponibles
            .reduce(0) { $0 + $1.price }
    }
    
    /// Nombre d'articles dans le panier
    var itemCount: Int {
        cartItems.count
    }
    
    /// Gère le logout en vidant le panier local
    private func handleLogout() {
        self.cartItems = []
        print("👋 [CartManager] Panier vidé après logout")
    }
    
    /// Helper : Extraire la catégorie depuis différentes formats
    private func extractCategory(_ category: String?) -> String {
        guard let category = category, !category.isEmpty else { return "Item" }
        return category.lowercased()
    }
}

// MARK: - CartItemModel
/// ✨ NOUVEAU : Modèle local pour représenter un item du panier
struct CartItemModel: Identifiable, Equatable {
    let id: String
    let userId: String
    let storeItemID: String
    let title: String
    let size: String
    let price: Double
    let imageURL: String?
    let addedAt: Date
    let status: String // "available" | "sold"
    
    var isSold: Bool {
        status == "sold"
    }
    
    var isAvailable: Bool {
        status == "available"
    }
}
