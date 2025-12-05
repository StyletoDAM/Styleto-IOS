// Labasniios/Views/Packs/SubscriptionDetailView.swift
// 📌 REMPLACER le fichier existant par celui-ci

import SwiftUI

struct SubscriptionDetailView: View {
    let plan: SubscriptionPlansView.PlanType
    
    @State private var isYearly = false
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var showCheckoutSheet = false
    @State private var checkoutUrl: String?
    
    var onSubscriptionSuccess: (() -> Void)? = nil
    
    // MARK: - Pricing
    
    private var monthlyPrice: String {
        plan == .premium ? "30 TND" : "90 TND"
    }
    
    private var yearlyPrice: String {
        plan == .premium ? "288 TND" : "864 TND"
    }
    
    private var pricePerMonthWhenYearly: String {
        plan == .premium ? "24 TND" : "72 TND"
    }
    
    private var planTitle: String {
        plan == .premium ? "Premium Access" : "Pro Seller"
    }
    
    private var planSubtitle: String {
        plan == .premium
            ? "For fashion enthusiasts who want to go further"
            : "For professional sellers who want to maximize their sales"
    }
    
    private var icon: String {
        plan == .premium ? "crown.fill" : "bag.fill"
    }
    
    private var iconBackground: Color {
        plan == .premium ? Color.themePrimary : Color(hex: "#4AA3A2")
    }
    
    private var features: [(String, String)] {
        if plan == .premium {
            return [
                ("camera.fill", "Unlimited Scans\nDetect as many clothes as you want"),
                ("sparkles", "Unlimited AI\nOutfit suggestions without limits"),
                ("person.2", "Premium 3D Avatar\nCustomize your virtual avatar"),
                ("bag", "Limited Sales\nUp to 3 items per month")
            ]
        } else { // Pro Seller
            return [
                ("camera.fill", "Unlimited Scans\nDetect as many clothes as you want"),
                ("sparkles", "Unlimited AI\nOutfit suggestions without limits"),
                ("bag.fill", "Unlimited Sales\nOn the Labas Store")
            ]
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with crown/bag
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(iconBackground.opacity(0.2))
                                .frame(width: 90, height: 90)
                            Image(systemName: icon)
                                .font(.system(size: 44, weight: .medium))
                                .foregroundColor(iconBackground)
                        }
                        
                        Text(planTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(planSubtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Monthly / Yearly toggle
                    HStack {
                        Text("Monthly")
                            .font(.headline)
                            .foregroundColor(isYearly ? .secondary : .primary)
                        
                        Spacer()
                        
                        Toggle("", isOn: $isYearly)
                            .toggleStyle(SwitchToggleStyle(tint: .themePrimary))
                        
                        Spacer()
                        
                        Text("Yearly")
                            .font(.headline)
                            .foregroundColor(isYearly ? .primary : .secondary)
                    }
                    .padding(.horizontal, 32)
                    
                    // Price
                    VStack(spacing: 8) {
                        Text(isYearly ? yearlyPrice : monthlyPrice)
                            .font(.system(size: 48, weight: .bold))
                        
                        Text(isYearly ? "per year · \(pricePerMonthWhenYearly)/month" : "per month")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if isYearly {
                            Text("Save 20%")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 20) {
                        Text("What's included")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ForEach(features, id: \.0) { iconName, text in
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: iconName)
                                    .font(.title2)
                                    .foregroundColor(iconBackground)
                                    .frame(width: 32)
                                
                                Text(text)
                                    .font(.callout)
                                    .foregroundColor(.primary.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                                
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            
            // Fixed bottom button + info
            VStack {
                Button {
                    Task {
                        await initiateSubscription()
                    }
                } label: {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(iconBackground.opacity(0.7))
                            .cornerRadius(16)
                    } else {
                        Text("Subscribe to \(planTitle)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(iconBackground)
                            .cornerRadius(16)
                    }
                }
                .disabled(isProcessing)
                .padding(.horizontal)
                
                // Good to know
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.orange)
                        Text("Good to know")
                            .font(.headline)
                    }
                    
                    BulletPoint(text: "Cancel anytime, no commitment")
                    BulletPoint(text: "Switch plans whenever you want")
                    BulletPoint(text: "Secure payment via Stripe")
                    BulletPoint(text: "Customer support available 7/7")
                }
                .padding()
                .background(Color.themeCard.opacity(0.7))
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .background(Color.themeBackground)
            
            // Navigation bar
            .navigationTitle("Pack Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    showSuccessAlert = false
                    onSubscriptionSuccess?()
                    dismiss()
                }
            } message: {
                Text("Your subscription has been activated successfully!")
            }
            .sheet(isPresented: $showCheckoutSheet) {
                if let url = checkoutUrl {
                    StripeCheckoutSheet(
                        checkoutUrl: url,
                        onSuccess: {
                            handlePaymentSuccess()
                        },
                        onCancel: {
                            handlePaymentCancel()
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Subscription Flow
    
    private func initiateSubscription() async {
        guard AppPreferences.shared.currentUser != nil else {
            errorMessage = "You must be logged in"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            let planType: SubscriptionPlan = plan == .premium ? .premium : .proSeller
            let interval: BillingInterval = isYearly ? .year : .month
            
            let response = try await StripeCheckoutService.shared.createCheckoutSession(
                plan: planType,
                interval: interval
            )
            
            guard let url = response.checkoutUrl else {
                throw NetworkError.serverMessage("No checkout URL received")
            }
            
            await MainActor.run {
                self.checkoutUrl = url
                self.showCheckoutSheet = true
                self.isProcessing = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to create checkout session: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }
    
    private func handlePaymentSuccess() {
        // Attendre un peu que le backend traite le webhook
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 secondes
            
            await MainActor.run {
                showSuccessAlert = true
                onSubscriptionSuccess?()
            }
        }
    }
    
    private func handlePaymentCancel() {
        isProcessing = false
        // Optionnel: afficher un message
    }
}

struct BulletPoint: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}
