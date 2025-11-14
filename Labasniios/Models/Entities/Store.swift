import Foundation

struct Store: Identifiable, Codable {
    let id: String
    let userId: UserInfo
    let clothesId: Clothe
    var price: Double
    var status: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, clothesId, price, status, createdAt, updatedAt
    }

    var title: String { clothesId.category! }
    var dateLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    var isAvailable: Bool { status == "available" }
}
