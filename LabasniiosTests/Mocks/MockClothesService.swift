import Foundation
@testable import Labasniios

/// Helper pour créer des Clothe dans les tests
extension Clothe {
    /// Initialiseur simplifié pour les tests
    static func testClothe(
        id: String = UUID().uuidString,
        imageURL: String = "https://example.com/image.jpg",
        processedImageURL: String? = nil,
        category: String? = "Top",
        season: String? = "Summer",
        color: String? = "Blue",
        style: String? = "Casual",
        acceptedCount: Int? = 0,
        rejectedCount: Int? = 0
    ) -> Clothe {
        // Créer un JSON pour décoder
        var json: [String: Any] = [
            "_id": id,
            "imageURL": imageURL
        ]
        
        if let processedImageURL = processedImageURL {
            json["processedImageURL"] = processedImageURL
        }
        if let category = category {
            json["category"] = category
        }
        if let season = season {
            json["season"] = season
        }
        if let color = color {
            json["color"] = color
        }
        if let style = style {
            json["style"] = style
        }
        if let acceptedCount = acceptedCount {
            json["acceptedCount"] = acceptedCount
        }
        if let rejectedCount = rejectedCount {
            json["rejectedCount"] = rejectedCount
        }
        
        let jsonData = try! JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(Clothe.self, from: jsonData)
    }
}

