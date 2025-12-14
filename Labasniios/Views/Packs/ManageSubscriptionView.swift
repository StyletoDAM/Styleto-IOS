// Views/Packs/ManageSubscriptionView.swift
// 📌 MISE À JOUR - Désactivation après annulation

import SwiftUI

struct ManageSubscriptionView: View {
    @StateObject private var viewModel = SubscriptionViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCancelConfirmation = false
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Current Plan Card
                    currentPlanCard
                    
                    // MARK: - Usage Stats
                    if let stats = viewModel.usageStats {
                        usageStatsSection(stats: stats)
                    }
                    
                    // MARK: - Cancel Button
                    if viewModel.canCancelSubscription {
                        cancelSubscriptionSection
                    }
                    
                    // MARK: - Info Card
                    infoCard
                }
                .padding()
            }
            .navigationTitle("Manage Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.themePrimary)
                }
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .task {
                await viewModel.loadSubscriptionData()
            }
            .alert("Cancel Subscription?", isPresented: $showCancelConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Yes, Cancel Subscription", role: .destructive) {
                    Task {
                        await viewModel.cancelSubscription()
                        if viewModel.successMessage != nil {
                            showSuccessAlert = true
                        }
                    }
                }
            } message: {
                Text("Your subscription will remain active until the end of the current billing period. You can still use all features until then.")
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    showSuccessAlert = false
                    // ✨ IMPORTANT: Rafraîchir les données après fermeture de l'alerte
                    Task {
                        await viewModel.loadSubscriptionData()
                    }
                }
            } message: {
                Text(viewModel.successMessage ?? "Subscription canceled successfully")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .overlay {
                if viewModel.isLoading || viewModel.isCanceling {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                }
            }
        }
    }
    
    // MARK: - Current Plan Card
    
    private var currentPlanCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: iconForPlan(viewModel.currentPlan))
                    .font(.system(size: 40))
                    .foregroundColor(colorForPlan(viewModel.currentPlan))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Plan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.currentPlan.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.themeText)
                }
                
                Spacer()
                
                if viewModel.currentPlan != .free {
                    VStack(alignment: .trailing, spacing: 4) {
                        // ✨ NOUVEAU: Badge différent si annulé
                        if viewModel.isCanceled {
                            Text("Canceled")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .cornerRadius(12)
                        } else {
                            Text("Active")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            if let expirationMsg = viewModel.expirationMessage {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                    Text(expirationMsg)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    // MARK: - Usage Stats Section
    
    private func usageStatsSection(stats: UsageStatsResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Usage This Month")
                .font(.headline)
                .foregroundColor(.themeText)
            
            VStack(spacing: 12) {
                UsageRow(
                    icon: "camera.fill",
                    title: "Clothing Scans",
                    used: stats.clothesDetection.used,
                    isUnlimited: stats.clothesDetection.isUnlimited,
                    limit: stats.clothesDetection.limitCount
                )
                
                UsageRow(
                    icon: "sparkles",
                    title: "Outfit Suggestions",
                    used: stats.outfitSuggestions.used,
                    isUnlimited: stats.outfitSuggestions.isUnlimited,
                    limit: stats.outfitSuggestions.limitCount
                )
                
                UsageRow(
                    icon: "bag.fill",
                    title: "Items for Sale",
                    used: stats.storeSelling.used,
                    isUnlimited: stats.storeSelling.isUnlimited,
                    limit: stats.storeSelling.limitCount
                )
            }
        }
        .padding(20)
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    // MARK: - Cancel Section
    
    private var cancelSubscriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cancel Subscription")
                .font(.headline)
                .foregroundColor(.themeText)
            
            // ✨ NOUVEAU: Message différent si déjà annulé
            if viewModel.isCanceled {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Your subscription has been canceled and will expire on \(viewModel.expirationDate)")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                Text("You can cancel your subscription at any time. You'll continue to have access until the end of your billing period.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button {
                    showCancelConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel Subscription")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isCanceling)
            }
        }
        .padding(20)
        .background(Color.themeCard)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Good to Know")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoBullet(text: "Your subscription renews automatically")
                InfoBullet(text: "You can upgrade or downgrade anytime")
                InfoBullet(text: "Cancellation takes effect at period end")
                InfoBullet(text: "No refunds for partial months")
            }
        }
        .padding(20)
        .background(Color.themeCard.opacity(0.7))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Functions
    
    private func iconForPlan(_ plan: SubscriptionPlan) -> String {
        switch plan {
        case .free: return "star.circle.fill"
        case .premium: return "crown.fill"
        case .proSeller: return "bag.fill"
        }
    }
    
    private func colorForPlan(_ plan: SubscriptionPlan) -> Color {
        switch plan {
        case .free: return Color.gray
        case .premium: return Color.themePrimary
        case .proSeller: return Color(hex: "#4AA3A2")
        }
    }
}

// MARK: - Supporting Views

private struct UsageRow: View {
    let icon: String
    let title: String
    let used: Int
    let isUnlimited: Bool
    let limit: Int?
    
    // ✅ Limiter used à la limite du plan actuel
    private var displayedUsed: Int {
        if isUnlimited {
            return used
        }
        if let limit = limit {
            return min(used, limit)
        }
        return used
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.themePrimary)
                .frame(width: 32)
            
            Text(title)
                .font(.callout)
                .foregroundColor(.themeText)
            
            Spacer()
            
            Text(isUnlimited ? "Unlimited" : "\(displayedUsed) used")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(isUnlimited ? .green : .themePrimary)
        }
        .padding(.vertical, 8)
    }
}

private struct InfoBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

#Preview {
    ManageSubscriptionView()
}
