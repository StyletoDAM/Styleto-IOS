//
//  StripeConfig.swift
//  Labasniios
//
//  Created by Aziz on 23/11/2025.
//

import Foundation
import Stripe
import StripePaymentSheet
import UIKit  // ✅ Pour UIColor.systemPink

/// Configuration centralisée pour Stripe
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
