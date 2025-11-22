import Foundation
import CoreData
import Combine

class CartManager: ObservableObject {
    static let shared = CartManager()
    
    private let context = PersistenceController.shared.container.viewContext
    
    @Published var cartItems: [CartItem] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // Cache de l'ID utilisateur pour éviter les accès @MainActor répétés
    private var cachedUserId: String?
    
    private init() {
        // 🔹 CORRECTION : Charger l'userId de manière synchrone au démarrage
        loadUserIdAndFetchCart()
        
        // Observer les changements d'utilisateur
        NotificationCenter.default.publisher(for: .userDidUpdate)
            .sink { [weak self] notification in
                Task { @MainActor in
                    self?.cachedUserId = AppPreferences.shared.currentUser?.id
                    self?.fetchCartItems()
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
    
    /// 🔹 NOUVEAU : Charge l'userId et le panier de manière synchrone
    private func loadUserIdAndFetchCart() {
        Task { @MainActor in
            self.cachedUserId = AppPreferences.shared.currentUser?.id
            
            if let userId = self.cachedUserId {
                print("✅ [CartManager] Utilisateur chargé: \(userId)")
            } else {
                print("⚠️ [CartManager] Aucun utilisateur connecté au démarrage")
            }
            
            // Charger le panier après avoir récupéré l'userId
            self.fetchCartItems()
        }
    }
    
    /// Récupère les articles du panier pour l'utilisateur connecté
    func fetchCartItems() {
        guard let userId = cachedUserId else {
            print("⚠️ [CartManager] Aucun utilisateur connecté – panier vide")
            DispatchQueue.main.async {
                self.cartItems = []
            }
            return
        }
        
        let request: NSFetchRequest<CartItem> = CartItem.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CartItem.addedAt, ascending: false)]
        
        do {
            let items = try context.fetch(request)
            DispatchQueue.main.async {
                self.cartItems = items
                print("✅ [CartManager] \(items.count) articles chargés pour l'utilisateur \(userId)")
            }
        } catch {
            print("❌ [CartManager] Erreur fetch panier: \(error)")
            DispatchQueue.main.async {
                self.cartItems = []
            }
        }
    }
    
    /// Ajoute un article au panier de l'utilisateur connecté
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
        
        // Vérifier si l'article existe déjà
        let request: NSFetchRequest<CartItem> = CartItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "storeItemID == %@ AND userId == %@",
            storeItem.id, userId
        )
        
        if let existing = try? context.fetch(request).first {
            print("ℹ️ [CartManager] Article déjà dans le panier")
            return
        }
        
        // Créer un nouvel article
        let newItem = CartItem(context: context)
        newItem.id = UUID().uuidString
        newItem.userId = userId
        newItem.storeItemID = storeItem.id
        newItem.title = storeItem.clothe?.category?.capitalized ?? "Article"
        newItem.size = storeItem.size
        newItem.price = storeItem.price
        newItem.imageURL = storeItem.clothe?.imageURL
        newItem.addedAt = Date()
        
        saveContext()
        fetchCartItems()
        
        print("✅ [CartManager] Article ajouté au panier de \(userId)")
    }
    
    /// Supprime un article du panier
    func removeFromCart(_ cartItem: CartItem) {
        context.delete(cartItem)
        saveContext()
        fetchCartItems()
        
        print("🗑️ [CartManager] Article supprimé du panier")
    }
    
    /// Vide tout le panier de l'utilisateur connecté
    func clearCart() {
        guard let userId = cachedUserId else {
            print("⚠️ [CartManager] Impossible de vider le panier : utilisateur non connecté")
            return
        }
        
        let request: NSFetchRequest<CartItem> = CartItem.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        
        if let items = try? context.fetch(request) {
            items.forEach { context.delete($0) }
            saveContext()
            fetchCartItems()
            
            print("🗑️ [CartManager] Panier vidé pour l'utilisateur \(userId)")
        }
    }
    
    /// Prix total du panier
    var totalPrice: Double {
        cartItems.reduce(0) { $0 + $1.price }
    }
    
    /// Nombre d'articles dans le panier
    var itemCount: Int {
        cartItems.count
    }
    
    /// Gère le logout en vidant le panier local
    private func handleLogout() {
        DispatchQueue.main.async {
            self.cartItems = []
        }
        print("👋 [CartManager] Panier vidé après logout")
    }
    
    /// Sauvegarde le contexte Core Data
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ [CartManager] Erreur sauvegarde: \(error)")
            }
        }
    }
}
