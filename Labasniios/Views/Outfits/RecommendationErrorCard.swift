// Labasniios/Views/Outfits/RecommendationErrorCard.swift
// 📌 NOUVEAU FICHIER - Créer ce fichier dans Xcode

import SwiftUI

struct RecommendationErrorCard: View {
    let message: String
    var onDismiss: () -> Void
    var onNavigateToStore: (() -> Void)? = nil
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showPremiumDetail = false // ✨ MODIFIÉ: Ouvrir directement SubscriptionDetailView
    
    // Détecte si c'est une erreur de quota
    private var isQuotaError: Bool {
        message.lowercased().contains("limit") ||
        message.lowercased().contains("quota") ||
        message.lowercased().contains("upgrade to premium")
    }
    
    // Détecte si c'est une erreur de vêtements manquants
    private var isMissingClothesError: Bool {
        message.lowercased().contains("missing items") ||
        message.lowercased().contains("add a top") ||
        message.lowercased().contains("add a bottom") ||
        message.lowercased().contains("add a pair of shoes")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: isQuotaError ? "crown.fill" : "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(isQuotaError ? .yellow : .orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(isQuotaError ? "Upgrade Required" : "Unable to Generate")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.themePrimary)
                    
                    if isQuotaError {
                        Text("You've reached your monthly limit")
                            .font(.system(size: 11))
                            .foregroundColor(.themeSecondaryText)
                    }
                }
                
                Spacer()
                
                // Bouton fermer
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.themeSecondaryText)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.themeSoftPink.opacity(0.2)))
                }
            }
            
            // Message
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.themeSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            // Boutons d'action
            if isQuotaError {
                // ✨ QUOTA ERROR: Bouton Upgrade vers Premium (directement vers SubscriptionDetailView)
                Button {
                    showPremiumDetail = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                        Text("Upgrade to Premium")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.themePrimary)
                    .cornerRadius(10)
                }
            } else if isMissingClothesError {
                // ✨ MISSING CLOTHES: Bouton Add More Clothes
                Button {
                    onNavigateToStore?()
                    onDismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add More Clothes")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.themePrimary)
                    .cornerRadius(10)
                }
            } else {
                // ✨ AUTRE ERREUR: Bouton Try Again
                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.themeTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.themeTeal.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
        .sheet(isPresented: $showPremiumDetail) {
            // ✨ MODIFIÉ: Ouvre directement la page de détail Premium
            SubscriptionDetailView(plan: .premium) {
                // Callback après souscription réussie
                onDismiss()
            }
        }
    }
}

#Preview("Quota Error") {
    RecommendationErrorCard(
        message: "You have reached your monthly limit for outfit suggestions. Upgrade to Premium for unlimited suggestions.",
        onDismiss: {},
        onNavigateToStore: {}
    )
    .padding()
    .background(Color.themeBackground)
}

#Preview("Missing Clothes") {
    RecommendationErrorCard(
        message: "Your wardrobe is missing items for the \"formal\" style. Please add a top and a bottom to continue.",
        onDismiss: {},
        onNavigateToStore: {}
    )
    .padding()
    .background(Color.themeBackground)
}
