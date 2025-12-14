// Views/Packs/PackProfileCard.swift
// ✨ MISE À JOUR - Écoute les changements d'abonnement

import SwiftUI

struct PackProfileCard: View {
    
    @ObservedObject private var viewModel = SubscriptionViewModel.shared
    @State private var showPlans = false
    @State private var showManageSubscription = false
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Card 1: Pack actuel + Usage
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: viewModel.currentPlan == .free ? "star.circle.fill" : "crown.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.themePrimary.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your current pack")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                        
                        Text(viewModel.currentPlan.displayName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.themePrimary)
                    }
                    
                    Spacer()
                    
                    // ✨ Bouton "Manage" pour les abonnements payants
                    if viewModel.currentPlan != .free {
                        Button {
                            showManageSubscription = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Manage")
                                    .font(.system(size: 14, weight: .semibold))
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.themePrimary)
                            .cornerRadius(12)
                        }
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.themeSecondaryText)
                            .onTapGesture { showPlans = true }
                    }
                }
                
                Text("Your usage this month")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.themeText.opacity(0.9))
                
                if let stats = viewModel.usageStats {
                    VStack(spacing: 12) {
                        ProgressRow(
                            icon: "tshirt",
                            title: "Clothing scans",
                            used: stats.clothesDetection.used,
                            isUnlimited: stats.clothesDetection.isUnlimited,
                            remaining: stats.clothesDetection.remainingCount ?? 0,
                            limit: stats.clothesDetection.limitCount
                        )
                        ProgressRow(
                            icon: "wand.and.stars",
                            title: "Outfit suggestions",
                            used: stats.outfitSuggestions.used,
                            isUnlimited: stats.outfitSuggestions.isUnlimited,
                            remaining: stats.outfitSuggestions.remainingCount ?? 0,
                            limit: stats.outfitSuggestions.limitCount
                        )
                        ProgressRow(
                            icon: "bag",
                            title: "Items for sale",
                            used: stats.storeSelling.used,
                            isUnlimited: stats.storeSelling.isUnlimited,
                            remaining: stats.storeSelling.remainingCount ?? 0,
                            limit: stats.storeSelling.limitCount
                        )
                    }
                } else {
                    placeholderRows
                }
            }
            .padding(20)
            .background(Color.themeCard)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // MARK: - Card 2: Upgrade (seulement si pas PRO_SELLER)
            if viewModel.currentPlan != .proSeller {
                upgradeCard
            }
        }
        .padding(.horizontal, 16)
        .task {
            await viewModel.loadSubscriptionData()
        }
        // ✨ NOUVEAU: Écouter les changements d'abonnement
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionDidUpdate)) { _ in
            print("🔔 [PackProfileCard] Subscription updated notification received")
            Task {
                await viewModel.loadSubscriptionData()
            }
        }
        .sheet(isPresented: $showPlans) {
            SubscriptionPlansView()
        }
        .sheet(isPresented: $showManageSubscription) {
            ManageSubscriptionView()
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.successMessage = nil
            }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }
    
    private var upgradeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                
                Text(viewModel.currentPlan == .free ? "Upgrade to Premium" : "Go Pro Seller")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(viewModel.currentPlan == .free
                ? "Unlock all AI features\nand create your personalized 3D avatar."
                : "Unlimited sales + all Premium features")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.95))
                .lineSpacing(4)
            
            Button {
                showPlans = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("View packs")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.themePrimary))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [Color.themePrimary.opacity(0.85), Color.themePrimary.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .shadow(color: Color.themePrimary.opacity(0.4), radius: 15, x: 0, y: 8)
    }
    
    private var placeholderRows: some View {
        VStack(spacing: 12) {
            ForEach(0..<3) { _ in
                ProgressRow(icon: "tshirt", title: "Loading...", used: 0, isUnlimited: false, remaining: 1, limit: 1)
            }
        }
        .redacted(reason: .placeholder)
    }
}

// MARK: - Progress Row
private struct ProgressRow: View {
    let icon: String
    let title: String
    let used: Int
    let isUnlimited: Bool
    let remaining: Int
    let limit: Int?
    
    // ✅ Calculer la limite réelle et limiter l'affichage
    private var actualLimit: Int {
        if let limit = limit {
            return limit
        }
        // Si pas de limite explicite, calculer depuis used + remaining
        return max(0, used + remaining)
    }
    
    // ✅ Limiter used à la limite du plan actuel
    private var displayedUsed: Int {
        isUnlimited ? used : min(used, actualLimit)
    }
    
    private var displayText: String {
        isUnlimited ? "Unlimited" : "\(displayedUsed)/\(actualLimit)"
    }
    
    private var progress: Double {
        isUnlimited ? 1.0 : Double(displayedUsed) / Double(actualLimit)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.themeTeal)
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.themeText)
                
                Spacer()
                
                Text(displayText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isUnlimited ? .green : .themePrimary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.themeSoftPink.opacity(0.25))
                        .frame(height: 9)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isUnlimited ? Color.green.opacity(0.7) : .themeTeal)
                        .frame(width: geo.size.width * progress, height: 9)
                }
            }
            .frame(height: 9)
        }
    }
}

#Preview {
    ScrollView {
        PackProfileCard()
            .padding(.top, 50)
            .background(Color.themeBackground)
    }
}
