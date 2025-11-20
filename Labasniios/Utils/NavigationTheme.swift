// NavigationTheme.swift
import SwiftUI

struct NavigationTheme: ViewModifier {
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Couleur du titre (normal + large title)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(dynamicProvider: { _ in
                UIColor(Color.themePrimary)   // ← UIColor dynamique
            })
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(dynamicProvider: { _ in
                UIColor(Color.themePrimary)
            })
        ]
        
        // Couleur de la flèche retour et des boutons de navigation
        UINavigationBar.appearance().tintColor = UIColor(dynamicProvider: { _ in
            UIColor(Color.themePrimary)
        })
        
        // Applique l’apparence partout
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func navigationTheme() -> some View {
        self.modifier(NavigationTheme())
    }
}
