import SwiftUI

struct CategoryColors {
    static func color(for category: String) -> Color {
        // Normalisation : minuscules + suppression 's' final
        let cat = category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = cat.hasSuffix("s") ? String(cat.dropLast()) : cat

        switch normalized {
        // Tops
        case "tshirt", "haut", "chemise":
            return Color(hex: "#A7E0E0") // Light Blue
        // Pants
        case "pantalon", "jean", "bas":
            return Color(hex: "#4D5F8F") // Dark Blue
        // Dress
        case "robe", "dress":
            return Color(hex: "#DB6A8F") // Pink
        // Shoes
        case "chaussure", "basket":
            return Color(hex: "#4A4A4A") // Dark Gray
        // Accessories
        case "accessoire", "sac", "bijou":
            return Color(hex: "#E8AABE") // Light Pink
        // Default
        default:
            return Color(hex: "#D3D3D3") // Light Gray
        }
    }
}

// Extension pour Color(hex:)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 255, (int >> 8) & 255, int & 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 255, (int >> 16) & 255, (int >> 8) & 255, int & 255)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
