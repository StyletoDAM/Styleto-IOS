//
//  CategoryColors.swift
//  Labasniios
//
//  Utilitaires pour les couleurs de catégories de vêtements
//
//  Ce fichier fournit des fonctions utilitaires pour obtenir des couleurs
//  adaptées aux différentes catégories de vêtements. Les couleurs varient
//  selon le mode clair/sombre pour maintenir un bon contraste et une
//  lisibilité optimale.
//
//  Architecture : Structure utilitaire statique
//  Dépendances : SwiftUI
//

import SwiftUI

/**
 * Utilitaires pour les couleurs de catégories de vêtements
 * 
 * Cette structure fournit des méthodes statiques pour obtenir des couleurs
 * adaptées aux différentes catégories de vêtements. Les couleurs sont
 * automatiquement ajustées selon le ColorScheme (clair/sombre) pour
 * maintenir un bon contraste.
 * 
 * Catégories supportées :
 * - Tops (tshirt, haut, chemise)
 * - Pants (pantalon, jean, bas)
 * - Dresses (robe, dress)
 * - Shoes (chaussure, basket)
 * - Accessories (accessoire, sac, bijou)
 * 
 * Les couleurs sont normalisées (pluriels supprimés, espaces trimmés)
 * pour garantir une correspondance cohérente.
 */
struct CategoryColors {
    // Public API that adapts to the provided color scheme.
    // Pass `colorScheme` from your views using `@Environment(\.colorScheme)`.
    static func color(for category: String, in colorScheme: ColorScheme) -> Color {
        let normalized = normalize(category)
        let palette = palette(for: normalized)
        switch colorScheme {
        case .dark:
            return Color(hex: palette.dark)
        default:
            return Color(hex: palette.light)
        }
    }

    // Backward-compatible API (kept to avoid breaking callers).
    // Defaults to light variant; prefer calling the `in colorScheme:` version for adaptive behavior.
    static func color(for category: String) -> Color {
        let normalized = normalize(category)
        let palette = palette(for: normalized)
        return Color(hex: palette.light)
    }

    // Normalize plurals and whitespace, keep previous behavior of removing trailing 's'.
    private static func normalize(_ category: String) -> String {
        let cat = category
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cat.hasSuffix("s") ? String(cat.dropLast()) : cat
    }

    // Provide light/dark pairs for each logical category.
    // Colors are chosen to maintain contrast in dark mode.
    private static func palette(for normalized: String) -> (light: String, dark: String) {
        switch normalized {
        // Tops
        case "tshirt", "haut", "chemise":
            return (light: "#A7E0E0", dark: "#6FB8B8")
        // Pants
        case "pantalon", "jean", "bas":
            return (light: "#4D5F8F", dark: "#3C4B70")
        // Dress
        case "robe", "dress":
            return (light: "#DB6A8F", dark: "#B85476")
        // Shoes
        case "chaussure", "basket":
            return (light: "#4A4A4A", dark: "#DADADA") // Invert to keep visibility on dark backgrounds
        // Accessories
        case "accessoire", "sac", "bijou":
            return (light: "#E8AABE", dark: "#C9879B")
        // Default
        default:
            return (light: "#D3D3D3", dark: "#8A8A8A")
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
