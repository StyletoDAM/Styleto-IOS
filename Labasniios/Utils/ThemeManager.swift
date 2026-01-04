//
//  ThemeManager.swift
//  Labasniios
//
//  Gestionnaire de thème de l'application
//
//  Ce fichier gère le système de thème dynamique de l'application Labasni.
//  Il supporte :
//  - Les modes clair/sombre avec suivi du thème système
//  - Les variantes de couleur basées sur le genre (Pink pour Female, Blue pour Male)
//  - La synchronisation automatique avec le genre de l'utilisateur
//  - Les transitions animées entre les thèmes
//
//  Architecture : Singleton avec ObservableObject (Combine)
//  Dépendances : SwiftUI, UIKit, Combine
//

import SwiftUI
import UIKit

// MARK: - Theme Mode

/**
 * Enumération des modes de thème disponibles
 * 
 * Les modes définissent si l'application utilise le thème clair, sombre,
 * ou suit automatiquement les préférences système de l'utilisateur.
 */
enum ThemeMode: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

// MARK: - Theme Variant

/**
 * Enumération des variantes de couleur du thème
 * 
 * Les variantes définissent la palette de couleurs utilisée :
 * - Pink : Palette rose (par défaut pour les utilisatrices)
 * - Blue : Palette bleue (par défaut pour les utilisateurs masculins)
 * 
 * La variante est synchronisée automatiquement avec le genre de l'utilisateur
 * mais peut être modifiée manuellement dans les paramètres.
 */
enum ThemeVariant: String, CaseIterable {
    case pink = "Pink"
    case blue = "Blue"
}

// MARK: - Theme Protocol

/**
 * Protocole définissant l'interface d'un thème
 * 
 * Tous les thèmes (LightTheme, DarkTheme) doivent implémenter ce protocole
 * pour fournir les couleurs nécessaires à l'interface utilisateur.
 * Les couleurs varient selon le genre de l'utilisateur (isMale).
 */
protocol Theme {
    var primary: Color { get }
    var secondary: Color { get }
    var softPink: Color { get }
    var aqua: Color { get }
    var teal: Color { get }
    var background: Color { get }
    var card: Color { get }
    var text: Color { get }
    var secondaryText: Color { get }
}

// MARK: - Light Theme

/**
 * Thème clair de l'application
 * 
 * Ce thème définit la palette de couleurs pour le mode clair.
 * Les couleurs varient selon le genre de l'utilisateur :
 * - Male : Palette bleue/teal
 * - Female : Palette rose/pink
 */
struct LightTheme: Theme {
    let isMale: Bool
    
    var primary: Color {
        isMale ? Color(hex: "#4AA3A2") : Color(hex: "#CA3C66")
    }
    
    var secondary: Color {
        isMale ? Color(hex: "#6BC4C3") : Color(hex: "#DB6A8F")
    }
    
    var softPink: Color {
        isMale ? Color(hex: "#A7E0E0") : Color(hex: "#E8AABE")
    }
    
    var aqua: Color {
        isMale ? Color(hex: "#E8AABE") : Color(hex: "#A7E0E0")
    }
    
    var teal: Color {
        isMale ? Color(hex: "#CA3C66") : Color(hex: "#4AA3A2")
    }
    
    let background = Color(.systemGroupedBackground)
    let card = Color.white
    
    var text: Color {
        isMale ? Color(hex: "#CA3C66") : Color(hex: "#4AA3A2")
    }
    
    let secondaryText = Color.secondary
}

// MARK: - Dark Theme

/**
 * Thème sombre de l'application
 * 
 * Ce thème définit la palette de couleurs pour le mode sombre.
 * Les couleurs sont plus saturées et contrastées que le thème clair
 * pour une meilleure lisibilité en conditions de faible luminosité.
 * Les couleurs varient selon le genre de l'utilisateur.
 */
struct DarkTheme: Theme {
    let isMale: Bool
    
    var primary: Color {
        isMale ? Color(hex: "#6BC4C3") : Color(hex: "#E85C8A")
    }
    
    var secondary: Color {
        isMale ? Color(hex: "#B8E8E8") : Color(hex: "#F07BA3")
    }
    
    var softPink: Color {
        isMale ? Color(hex: "#B8E8E8") : Color(hex: "#F5B5C8")
    }
    
    var aqua: Color {
        isMale ? Color(hex: "#F5B5C8") : Color(hex: "#B8E8E8")
    }
    
    var teal: Color {
        isMale ? Color(hex: "#E85C8A") : Color(hex: "#6BC4C3")
    }
    
    let background = Color(hex: "#1A1A2E")
    let card = Color(hex: "#2A2A3E")
    
    var text: Color {
        isMale ? Color(hex: "#F5B5C8") : Color(hex: "#E0E0E0")
    }
    
    let secondaryText = Color(hex: "#B0B0B0")
}

// MARK: - Theme Manager

/**
 * Gestionnaire de thème global de l'application
 * 
 * Cette classe gère le thème de l'application de manière centralisée.
 * Elle :
 * - Observe les changements du thème système
 * - Synchronise la variante avec le genre de l'utilisateur
 * - Publie les changements de thème pour la réactivité SwiftUI
 * - Gère les transitions animées entre les thèmes
 * 
 * Le thème est persistant via @AppStorage et est restauré au démarrage.
 * 
 * @see ObservableObject pour la réactivité avec SwiftUI
 * @see @MainActor pour l'exécution sur le thread principal
 */
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme
    @AppStorage("selectedTheme") private var selectedThemeMode: String = ThemeMode.system.rawValue
    @AppStorage("selectedThemeVariant") private var selectedThemeVariant: String = ThemeVariant.pink.rawValue
    
    private var themeMode: ThemeMode {
        get {
            ThemeMode(rawValue: selectedThemeMode) ?? .system
        }
        set {
            selectedThemeMode = newValue.rawValue
            updateTheme()
        }
    }
    
    private init() {
        // Initialiser la variante de thème basée sur le genre de l'utilisateur si disponible
        if let user = AppPreferences.shared.currentUser {
            let isMale = user.gender == .male
            selectedThemeVariant = isMale ? ThemeVariant.blue.rawValue : ThemeVariant.pink.rawValue
        }
        self.currentTheme = LightTheme(isMale: false)
        updateTheme()
    }
    
    func setThemeMode(_ mode: ThemeMode) {
        themeMode = mode
        AppPreferences.shared.saveThemeMode(mode)
    }
    
    func getThemeMode() -> ThemeMode {
        return themeMode
    }
    
    func getThemeVariant() -> ThemeVariant {
        return ThemeVariant(rawValue: selectedThemeVariant) ?? .pink
    }
    
    func setThemeVariant(_ variant: ThemeVariant) {
        selectedThemeVariant = variant.rawValue
        updateTheme()
    }
    
    func updateThemeBasedOnUser() {
        // ✨ Mettre à jour la variante de thème basée sur le genre de l'utilisateur actuel
        if let user = AppPreferences.shared.currentUser {
            let isMale = user.gender == .male
            let newVariant = isMale ? ThemeVariant.blue : ThemeVariant.pink
            
            // Mettre à jour la variante seulement si elle a changé
            if selectedThemeVariant != newVariant.rawValue {
                selectedThemeVariant = newVariant.rawValue
            }
        }
        updateTheme()
    }
    
    // NOUVELLE MÉTHODE: Met à jour le thème en fonction du sexe de l'utilisateur ou de la variante choisie
    func updateTheme() {
        let shouldUseDark: Bool
        switch themeMode {
        case .light:
            shouldUseDark = false
        case .dark:
            shouldUseDark = true
        case .system:
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                shouldUseDark = window.traitCollection.userInterfaceStyle == .dark
            } else {
                shouldUseDark = false
            }
        }
        
        // Utiliser la variante de thème choisie (Pink = Female, Blue = Male)
        let variant = getThemeVariant()
        let isMale = variant == .blue
        
        withAnimation(.easeInOut(duration: 0.35)) {
            currentTheme = shouldUseDark ? DarkTheme(isMale: isMale) : LightTheme(isMale: isMale)
        }
    }
    
    func observeSystemTheme() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTheme()
        }
    }
    
}

// MARK: - Color Extension for Theme

/**
 * Extension Color pour accéder facilement aux couleurs du thème
 * 
 * Cette extension fournit des propriétés statiques pour accéder
 * aux couleurs du thème actuel depuis n'importe où dans l'application.
 * Toutes les propriétés sont @MainActor car elles dépendent de ThemeManager.
 * 
 * Exemple d'utilisation :
 * ```swift
 * Text("Hello")
 *     .foregroundColor(.themePrimary)
 * ```
 */
extension Color {
    @MainActor
    static var themePrimary: Color {
        ThemeManager.shared.currentTheme.primary
    }
    
    @MainActor
    static var themeSecondary: Color {
        ThemeManager.shared.currentTheme.secondary
    }
    
    @MainActor
    static var themeSoftPink: Color {
        ThemeManager.shared.currentTheme.softPink
    }
    
    @MainActor
    static var themeAqua: Color {
        ThemeManager.shared.currentTheme.aqua
    }
    
    @MainActor
    static var themeTeal: Color {
        ThemeManager.shared.currentTheme.teal
    }
    
    @MainActor
    static var themeBackground: Color {
        ThemeManager.shared.currentTheme.background
    }
    
    @MainActor
    static var themeCard: Color {
        ThemeManager.shared.currentTheme.card
    }
    
    @MainActor
    static var themeText: Color {
        ThemeManager.shared.currentTheme.text
    }
    
    @MainActor
    static var themeSecondaryText: Color {
        ThemeManager.shared.currentTheme.secondaryText
    }
}
