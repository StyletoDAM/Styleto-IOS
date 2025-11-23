import SwiftUI
import UIKit

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

// MARK: - Theme Variant
enum ThemeVariant: String, CaseIterable {
    case pink = "Pink"
    case blue = "Blue"
}

// MARK: - Theme Protocol
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
        updateTheme() // C'est tout ! Elle fait déjà tout le boulot
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
