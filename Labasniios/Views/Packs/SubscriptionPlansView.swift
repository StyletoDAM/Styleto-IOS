import SwiftUI
private struct PlanCard: View {
    let plan: SubscriptionPlansView.PlanType
    let isSelected: Bool
    let isCurrentPlan: Bool
    let price: String
    let features: [String]
    let icon: String
    let iconColor: Color
    let badge: String?
    let backgroundGradient: LinearGradient?
    let onUpgradeTapped: () -> Void  // Nouveau callback
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.rawValue)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.themeText)
                    Text(price)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.themePrimary)
                }
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.themePrimary)
                        .cornerRadius(20)
                }
                
                if isCurrentPlan {
                    Text("Current Pack")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.themeTeal.opacity(0.15))
                        .foregroundColor(.themeTeal)
                        .cornerRadius(20)
                }
            }
            
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.themePrimary)
                        .font(.system(size: 20))
                    Text(feature)
                        .font(.system(size: 15))
                        .foregroundColor(.themeText.opacity(0.9))
                    Spacer()
                }
            }
            
            if !isCurrentPlan {
                Button {
                    onUpgradeTapped()
                } label: {
                    Text("View details & subscribe")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(plan == .premium ? Color.themePrimary : Color(hex: "#4AA3A2"))
                        )
                }
                .buttonStyle(.plain)
            } else {
                Text("You already use this pack")
                    .font(.caption)
                    .foregroundColor(.themeSecondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            backgroundGradient ?? LinearGradient(colors: [Color.themeCard], startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isSelected ? Color.themePrimary.opacity(0.9) : Color.clear, lineWidth: isSelected ? 2.5 : 0)
        )
        .padding(.horizontal)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isSelected)
        .onTapGesture {
            if !isCurrentPlan {
                withAnimation {
                    // Optionnel : tu peux garder la sélection visuelle
                }
            }
        }
    }
}
struct SubscriptionPlansView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PlanType = .free
    private let currentUserPlan: PlanType = .free
    
    // Ajoute ces deux states pour gérer l'affichage du détail
    @State private var showingPremiumDetail = false
    @State private var showingProDetail = false
    
    enum PlanType: String, CaseIterable {
        case free = "Free Pack"
        case premium = "Premium Access"
        case pro = "Pro Seller"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Free Pack
                    // MARK: - Free Pack
                    PlanCard(
                        plan: .free,
                        isSelected: selectedPlan == .free,
                        isCurrentPlan: currentUserPlan == .free,
                        price: "Free",
                        features: [
                            "5 clothing scans / month",
                            "3 outfit suggestions / month",
                            "3 items for sale / month",
                            "Basic wardrobe access"
                        ],
                        icon: "star.circle.fill",
                        iconColor: Color.themePrimary.opacity(0.8),
                        badge: nil,
                        backgroundGradient: nil,
                        onUpgradeTapped: { }
                    )
                    
                    // MARK: - Premium Access
                    PlanCard(
                        plan: .premium,
                        isSelected: selectedPlan == .premium,
                        isCurrentPlan: currentUserPlan == .premium,
                        price: "9.99 DT/month",
                        features: [
                            "Unlimited clothing detection",
                            "Unlimited outfit suggestions",
                            "3 items for sale / month",
                            "Personalized 3D Avatar"
                        ],
                        icon: "crown.fill",
                        iconColor: .white,
                        badge: "Most Popular",
                        backgroundGradient: LinearGradient(
                            colors: [
                                Color.themePrimary.opacity(0.15),
                                Color.themePrimary.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        onUpgradeTapped: {
                            showingPremiumDetail = true
                        }
                    )
                    .sheet(isPresented: $showingPremiumDetail) {
                        SubscriptionDetailView(plan: .premium)
                    }
                    
                    // MARK: - Pro Seller
                    PlanCard(
                        plan: .pro,
                        isSelected: selectedPlan == .pro,
                        isCurrentPlan: currentUserPlan == .pro,
                        price: "24.99 DT/month",
                        features: [
                            "Unlimited clothing detection",
                            "Unlimited outfit suggestions",
                            "Unlimited sales on the Store"
                        ],
                        icon: "bag.fill",
                        iconColor: .white,
                        badge: nil,
                        backgroundGradient: LinearGradient(
                            colors: [
                                Color(hex: "#4AA3A2").opacity(0.12),
                                Color(hex: "#6BC4C3").opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        onUpgradeTapped: {
                            showingProDetail = true
                        }
                    )
                    .sheet(isPresented: $showingProDetail) {
                        SubscriptionDetailView(plan: .pro)
                    }
                    
                    // Tip
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.orange)
                        Text("Tip: Upgrade to Premium or Pro Seller anytime. Cancel whenever you want, no commitment.")
                            .font(.caption)
                            .foregroundColor(.themeSecondaryText)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding()
                    .background(Color.themeCard.opacity(0.7))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Choose Your Pack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.themePrimary)
                    }
                }
            }
            .background(Color.themeBackground.ignoresSafeArea())
        }
    }
}
