import SwiftUI

struct SubscriptionPlansView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPremiumDetail = false
    @State private var showingProDetail = false
    @State private var currentUserPlan: PlanType = .free
    @State private var isLoadingPlan = true
    @State private var refreshTrigger = false
    
    enum PlanType: String, CaseIterable {
        case free = "Free Pack"
        case premium = "Premium Access"
        case pro = "Pro Seller"
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoadingPlan {
                    ProgressView("Loading your plan...")
                        .progressViewStyle(.circular)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Free Pack
                            PlanCard(
                                plan: .free,
                                isSelected: false,
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
                            
                            // Premium Pack
                            PlanCard(
                                plan: .premium,
                                isSelected: false,
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
                                    colors: [Color.themePrimary.opacity(0.15), Color.themePrimary.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                onUpgradeTapped: {
                                    guard currentUserPlan != .premium else { return }
                                    showingPremiumDetail = true
                                }
                            )
                            .disabled(currentUserPlan == .premium)
                            .opacity(currentUserPlan == .premium ? 0.7 : 1.0)
                            .sheet(isPresented: $showingPremiumDetail) {
                                SubscriptionDetailView(plan: .premium) {
                                    refreshTrigger.toggle()
                                }
                            }
                            
                            // Pro Seller Pack
                            PlanCard(
                                plan: .pro,
                                isSelected: false,
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
                                    colors: [Color(hex: "#4AA3A2").opacity(0.12), Color(hex: "#6BC4C3").opacity(0.06)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                onUpgradeTapped: {
                                    guard currentUserPlan != .pro else { return }
                                    showingProDetail = true
                                }
                            )
                            .disabled(currentUserPlan == .pro)
                            .opacity(currentUserPlan == .pro ? 0.7 : 1.0)
                            .sheet(isPresented: $showingProDetail) {
                                SubscriptionDetailView(plan: .pro) {
                                    refreshTrigger.toggle()
                                }
                            }
                            
                            // Tip Section
                            HStack {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(.orange)
                                Text("Tip: Upgrade to Premium or Pro Seller anytime. Cancel whenever you want, no commitment.")
                                    .font(.caption)
                                    .foregroundColor(.themeSecondaryText)
                                Spacer()
                            }
                            .padding()
                            .background(Color.themeCard.opacity(0.7))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Choose Your Pack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundColor(.themePrimary)
                }
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .onAppear {
                Task { await fetchCurrentPlan() }
            }
            .onChange(of: refreshTrigger) {
                Task { await fetchCurrentPlan() }
            }
            // ✅ Écouter la notification pour fermer toutes les vues
            .onReceive(NotificationCenter.default.publisher(for: .dismissAllSubscriptionViews)) { _ in
                dismiss()
            }
        }
    }
    
    private func fetchCurrentPlan() async {
        do {
            let subscription = try await SubscriptionService.shared.getMySubscription()
            await MainActor.run {
                switch subscription.plan.rawValue.lowercased() {
                case "premium":
                    currentUserPlan = .premium
                case "pro_seller", "pro":
                    currentUserPlan = .pro
                default:
                    currentUserPlan = .free
                }
                isLoadingPlan = false
            }
        } catch {
            await MainActor.run {
                currentUserPlan = .free
                isLoadingPlan = false
            }
        }
    }
}

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
    let onUpgradeTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
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
                
                if isCurrentPlan {
                    Text("Current Pack")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.themeTeal.opacity(0.15))
                        .foregroundColor(.themeTeal)
                        .cornerRadius(20)
                } else if let badge = badge {
                    Text(badge)
                        .font(.caption).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.themePrimary)
                        .cornerRadius(20)
                }
            }
            
            // Features
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.themePrimary)
                    Text(feature)
                        .font(.system(size: 15))
                        .foregroundColor(.themeText.opacity(0.9))
                    Spacer()
                }
            }
            
            // Action button
            if plan == .free {
                if isCurrentPlan {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.themeTeal)
                        Text("This is your current pack")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.themeText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.themeTeal.opacity(0.1))
                    .cornerRadius(16)
                } else {
                    Text("Default pack for all users")
                        .font(.system(size: 14))
                        .foregroundColor(.themeSecondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            } else {
                if isCurrentPlan {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.themeTeal)
                        Text("You already have this pack")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.themeText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.themeTeal.opacity(0.1))
                    .cornerRadius(16)
                } else {
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
                }
            }
        }
        .padding(20)
        .background(backgroundGradient ?? LinearGradient(colors: [Color.themeCard], startPoint: .top, endPoint: .bottom))
        .cornerRadius(24)
        .padding(.horizontal)
    }
}
