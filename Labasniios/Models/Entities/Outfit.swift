import Foundation
import CoreData

struct Outfit: Identifiable, Codable {
    let id: String
    let userId: UserInfo
    let clothesIds: [Clothe]
    let eventType: String?
    let weatherType: String?
    var status: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, clothesIds, eventType, weatherType, status, createdAt, updatedAt
    }

    var title: String { eventType ?? "Outfit" }
    var dateLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    var isFavorite: Bool { isLocallyFavorite }
    var itemsCount: Int { clothesIds.count }
    var previewClothes: [Clothe] { Array(clothesIds.prefix(3)) }
}

// MARK: - Local Favorites (CoreData)
extension Outfit {
    var isLocallyFavorite: Bool {
        let context = CoreDataManager.shared.container.viewContext
        let request: NSFetchRequest<FavoriteOutfit> = FavoriteOutfit.fetchRequest()
        request.predicate = NSPredicate(format: "outfitId == %@", id)
        request.fetchLimit = 1
        return (try? context.count(for: request)) ?? 0 > 0
    }
}
