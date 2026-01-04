//
//  NavigationTheme.swift
//  Labasniios
//
//  Modificateur de vue pour le thème de navigation
//
//  Ce fichier définit un ViewModifier pour appliquer un thème cohérent
//  à toutes les barres de navigation de l'application. Il configure
//  les couleurs, les styles de texte et l'apparence générale pour
//  s'adapter au thème dynamique de l'application.
//
//  Architecture : ViewModifier avec extension View
//  Dépendances : SwiftUI, UIKit
//

import SwiftUI

/**
 * Modificateur de vue pour le thème de navigation
 * 
 * Ce ViewModifier configure l'apparence de toutes les barres de navigation
 * pour qu'elles utilisent les couleurs du thème dynamique de l'application.
 * Il s'applique automatiquement à tous les écrans utilisant la navigation.
 * 
 * Configuration :
 * - Fond transparent pour un look moderne
 * - Couleur du titre adaptée au thème (themePrimary)
 * - Couleur des boutons de navigation adaptée au thème
 * - Support des titres normaux et larges
 * 
 * @see ViewModifier pour la modification de vues SwiftUI
 * @see UINavigationBarAppearance pour la configuration UIKit
 */
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
