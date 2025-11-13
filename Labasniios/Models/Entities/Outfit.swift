// Models/Entities/Outfit.swift
import Foundation

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

    var title: String { eventType ?? "Tenue" }
    var dateLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    var isFavorite: Bool { status == "accepted" }
    var itemsCount: Int { clothesIds.count }
    var previewClothes: [Clothe] { Array(clothesIds.prefix(3)) }
}
