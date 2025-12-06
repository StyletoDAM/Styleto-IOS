// Labasniios/Views/Outfits/OutfitSuggestionPaywallView.swift
// 📌 NOUVEAU FICHIER - Créer ce fichier dans Xcode

import SwiftUI

struct OutfitSuggestionPaywallView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingPremiumDetail = false // ✨ MODIFIÉ: Ouvrir directement SubscriptionDetailView
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Header rose
            ZStack {
                Color.themePrimary
                    .frame(height: 180)
                
                VStack(spacing: 16) {
                    // Croix en haut à droite
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.25)))
                    }
                    .offset(x: 140, y: -20)
                    
                    // Icône sparkles
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                        .frame(width: 90, height: 90)
                        .background(Circle().fill(.white.opacity(0.2)))
                    
                    Text("Outfit suggestion limit reached")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            VStack(spacing: 24) {
                
                // Message
                Text("You've reached your monthly limit of 3 AI outfit suggestions.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                Text("Upgrade to Premium for unlimited AI-powered outfit suggestions tailored to your style and weather.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Fonctionnalités Premium
                VStack(alignment: .leading, spacing: 16) {
                    Text("With Premium, you get:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach([
                        ("sparkles", "Unlimited AI outfit suggestions"),
                        ("camera.fill", "Unlimited clothing scans"),
                        ("person.2", "Personalized 3D avatar")
                    ], id: \.0) { icon, text in
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .foregroundColor(.themePrimary)
                                .font(.title3)
                            Text(text)
                                .font(.callout)
                                .foregroundColor(.primary.opacity(0.9))
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color.themeCard.opacity(0.8))
                .cornerRadius(20)
                
                // ✨ MODIFIÉ: Bouton Upgrade ouvre directement SubscriptionDetailView
                Button {
                    showingPremiumDetail = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Upgrade to Premium")
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.themePrimary)
                    .cornerRadius(20)
                }
                .padding(.horizontal)
                
                // Bouton Later
                Button("Later") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.themePrimary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.themePrimary, lineWidth: 2)
                )
                .padding(.horizontal)
                
                // Info cancel anytime
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.orange)
                    Text("Cancel anytime, no commitment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, -20)
            .background(Color.themeBackground)
            .cornerRadius(30, corners: [.topLeft, .topRight])
        }
        .ignoresSafeArea(edges: .top)
        
        // ✨ MODIFIÉ: Ouvre directement la page de détail Premium
        .sheet(isPresented: $showingPremiumDetail) {
            SubscriptionDetailView(plan: .premium) {
                // Callback après souscription réussie
                dismiss()
            }
        }
    }
}



#Preview {
    OutfitSuggestionPaywallView()
}
