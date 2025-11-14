import Foundation
import CoreData

class FavoritesService {
    static let shared = FavoritesService()
    private let context = CoreDataManager.shared.container.viewContext
    
    private init() {}
    
    func toggleFavorite(outfitId: String) {
        let request: NSFetchRequest<FavoriteOutfit> = FavoriteOutfit.fetchRequest()
        request.predicate = NSPredicate(format: "outfitId == %@", outfitId)
        request.fetchLimit = 1
        
        do {
            if let existing = try context.fetch(request).first {
                // SUPPRIMER
                context.delete(existing)
                print("FAVORI SUPPRIMÉ → ID: \(outfitId)")
            } else {
                // AJOUTER
                let favorite = FavoriteOutfit(context: context)
                favorite.outfitId = outfitId
                favorite.createdAt = Date()
                print("FAVORI AJOUTÉ → ID: \(outfitId)")
            }
            
            try context.save()
        } catch {
            print("ERREUR Core Data: \(error)")
        }
    }
    
    func isFavorite(outfitId: String) -> Bool {
        let request: NSFetchRequest<FavoriteOutfit> = FavoriteOutfit.fetchRequest()
        request.predicate = NSPredicate(format: "outfitId == %@", outfitId)
        request.fetchLimit = 1
        let count = (try? context.count(for: request)) ?? 0
        return count > 0
    }
}


