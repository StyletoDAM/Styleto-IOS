import Foundation
import CoreData
import Combine

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    private let context = CoreDataManager.shared.container.viewContext
    
    @Published var favoriteOutfits: [FavoriteOutfit] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // Cache de l'ID utilisateur
    private var cachedUserId: String?
    
    private init() {
        // Charger l'userId et les favoris de manière synchrone
        loadUserIdAndFetchFavorites()
        
        // Observer les changements d'utilisateur
        NotificationCenter.default.publisher(for: .userDidUpdate)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.cachedUserId = AppPreferences.shared.currentUser?.id
                    self?.fetchFavorites()
                    print("🔄 [FavoritesManager] Utilisateur mis à jour, favoris rechargés")
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
        
        // Observer les changements de favoris
        NotificationCenter.default.publisher(for: .favoritesDidChange)
            .sink { [weak self] _ in
                self?.fetchFavorites()
            }
            .store(in: &cancellables)
    }
    
    /// Charge l'userId et les favoris de manière synchrone
    private func loadUserIdAndFetchFavorites() {
        Task { @MainActor in
            self.cachedUserId = AppPreferences.shared.currentUser?.id
            
            if let userId = self.cachedUserId {
                print("✅ [FavoritesManager] Utilisateur chargé: \(userId)")
            } else {
                print("⚠️ [FavoritesManager] Aucun utilisateur connecté au démarrage")
            }
            
            self.fetchFavorites()
        }
    }
    
    /// Récupère les favoris pour l'utilisateur connecté
    func fetchFavorites() {
        guard let userId = cachedUserId else {
            print("⚠️ [FavoritesManager] Aucun utilisateur connecté – favoris vides")
            DispatchQueue.main.async {
                self.favoriteOutfits = []
            }
            return
        }
        
        let request: NSFetchRequest<FavoriteOutfit> = FavoriteOutfit.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FavoriteOutfit.createdAt, ascending: false)]
        
        do {
            let favorites = try context.fetch(request)
            DispatchQueue.main.async {
                self.favoriteOutfits = favorites
                print("✅ [FavoritesManager] \(favorites.count) favoris chargés pour l'utilisateur \(userId)")
            }
        } catch {
            print("❌ [FavoritesManager] Erreur fetch favoris: \(error)")
            DispatchQueue.main.async {
                self.favoriteOutfits = []
            }
        }
    }
    
    /// Toggle un favori
    func toggleFavorite(outfitId: String) {
        guard let userId = cachedUserId else {
            print("⚠️ [FavoritesManager] Impossible de toggle : utilisateur non connecté")
            
            // Tentative de récupération depuis AppPreferences
            Task { @MainActor in
                if let currentUser = AppPreferences.shared.currentUser {
                    print("   ℹ️ Utilisateur trouvé dans AppPreferences : \(currentUser.id)")
                    self.cachedUserId = currentUser.id
                    self.toggleFavorite(outfitId: outfitId)
                } else {
                    print("   ❌ Aucun utilisateur dans AppPreferences")
                }
            }
            return
        }
        
        let request: NSFetchRequest<FavoriteOutfit> = FavoriteOutfit.fetchRequest()
        request.predicate = NSPredicate(
            format: "outfitId == %@ AND userId == %@",
            outfitId,
            userId
        )
        request.fetchLimit = 1
        
        do {
            if let existing = try context.fetch(request).first {
                // SUPPRIMER
                context.delete(existing)
                print("✅ [FavoritesManager] Favori supprimé → Outfit: \(outfitId)")
            } else {
                // AJOUTER
                let favorite = FavoriteOutfit(context: context)
                favorite.outfitId = outfitId
                favorite.userId = userId
                favorite.createdAt = Date()
                print("✅ [FavoritesManager] Favori ajouté → Outfit: \(outfitId)")
            }
            
            saveContext()
            fetchFavorites()
            
            // Notifier le changement
            NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
        } catch {
            print("❌ [FavoritesManager] Erreur toggle: \(error.localizedDescription)")
        }
    }
    
    /// Vérifie si un outfit est favori
    func isFavorite(outfitId: String) -> Bool {
        guard let userId = cachedUserId else {
            return false
        }
        
        return favoriteOutfits.contains { $0.outfitId == outfitId && $0.userId == userId }
    }
    
    /// Nombre de favoris
    var favoritesCount: Int {
        favoriteOutfits.count
    }
    
    /// Gère le logout en vidant les favoris locaux
    private func handleLogout() {
        DispatchQueue.main.async {
            self.favoriteOutfits = []
        }
        print("👋 [FavoritesManager] Favoris vidés après logout")
    }
    
    /// Sauvegarde le contexte Core Data
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ [FavoritesManager] Erreur sauvegarde: \(error)")
            }
        }
    }
}

class FavoritesService {
    static let shared = FavoritesService()
    
    private init() {}
    
    func toggleFavorite(outfitId: String) {
        FavoritesManager.shared.toggleFavorite(outfitId: outfitId)
    }
    
    func isFavorite(outfitId: String) -> Bool {
        return FavoritesManager.shared.isFavorite(outfitId: outfitId)
    }
}
