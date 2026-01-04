//
//  StripeConfig.swift
//  Labasniios
//
//  Configuration centralisée pour Stripe
//
//  Ce fichier gère la configuration du SDK Stripe pour les paiements
//  dans l'application Labasni. Il centralise la clé publishable et
//  la configuration du Payment Sheet pour une utilisation cohérente
//  dans toute l'application.
//
//  Architecture : Singleton pattern
//  Dépendances : Foundation, Stripe, StripePaymentSheet, UIKit
//

import Foundation
import Stripe
import StripePaymentSheet
import UIKit

/**
 * Configuration centralisée pour Stripe
 * 
 * Cette classe implémente le pattern Singleton pour fournir une configuration
 * centralisée du SDK Stripe. Elle gère :
 * - L'initialisation du SDK avec la clé publishable
 * - La création de configurations personnalisées pour Payment Sheet
 * - Le style visuel des formulaires de paiement
 * 
 * La clé publishable est stockée directement dans le code (pour le développement).
 * En production, elle devrait être chargée depuis un fichier de configuration
 * sécurisé ou depuis les variables d'environnement.
 */
final class StripeConfig {
    static let shared = StripeConfig()
    
    // MARK: - Configuration
    private let publishableKey = "pk_test_51SWOK4FzjKYZqBoAhQtwRTUV8P1YSYxFi0uYoconGBDthaZsgCGJIcSWNgcCNLRs3OPEp9Kjaqzc6Z9OtLUMJDVF00jvhzluWY"
    
    private init() {}
    
    /// Initialise Stripe SDK (à appeler dans LabasniiosApp.swift)
    func initialize() {
        StripeAPI.defaultPublishableKey = publishableKey
        print("✅ [Stripe] SDK initialisé avec la clé publishable")
    }
    
    /// Crée la configuration du Payment Sheet
    func createPaymentSheetConfiguration(
        customerEmail: String,
        merchantDisplayName: String = "Styleto"
    ) -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = merchantDisplayName
        configuration.allowsDelayedPaymentMethods = false
        configuration.defaultBillingDetails.email = customerEmail
        
        // Style personnalisé
        var appearance = PaymentSheet.Appearance()
        appearance.colors.primary = UIColor.systemPink  // ✅ Utilise UIColor
        appearance.cornerRadius = 16.0
        configuration.appearance = appearance
        
        return configuration
    }
}
