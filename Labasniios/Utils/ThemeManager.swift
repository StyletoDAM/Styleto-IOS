import SwiftUI
import UIKit

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
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
    let primary = Color(hex: "#CA3C66")
    let secondary = Color(hex: "#DB6A8F")
    let softPink = Color(hex: "#E8AABE")
    let aqua = Color(hex: "#A7E0E0")
    let teal = Color(hex: "#4AA3A2")
    let background = Color(.systemGroupedBackground)
    let card = Color.white
    let text = Color._4aa3a2
    let secondaryText = Color.secondary
}

// MARK: - Dark Theme
struct DarkTheme: Theme {
    let primary = Color(hex: "#E85C8A") // Légèrement plus clair pour la visibilité
    let secondary = Color(hex: "#F07BA3")
    let softPink = Color(hex: "#F5B5C8")
    let aqua = Color(hex: "#B8E8E8")
    let teal = Color(hex: "#6BC4C3")
    let background = Color(hex: "#1A1A2E") // Fond sombre élégant
    let card = Color(hex: "#2A2A3E") // Carte sombre
    let text = Color(hex: "#E0E0E0") // Texte clair
    let secondaryText = Color(hex: "#B0B0B0") // Texte secondaire
}

// MARK: - Theme Manager
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme
    @AppStorage("selectedTheme") private var selectedThemeMode: String = ThemeMode.system.rawValue
    
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
        self.currentTheme = LightTheme()
        updateTheme()
    }
    
    func setThemeMode(_ mode: ThemeMode) {
        themeMode = mode
        // Sauvegarder dans AppPreferences
        AppPreferences.shared.saveThemeMode(mode)
    }
    
    func getThemeMode() -> ThemeMode {
        return themeMode
    }
    
    private func updateTheme() {
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
        
        withAnimation(.easeInOut(duration: 0.35)) {
            currentTheme = shouldUseDark ? DarkTheme() : LightTheme()
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
