//
//  UpgradeToProDialog.swift
//  Labasniios
//

import SwiftUI

struct UpgradeToProDialog: View {
    let onDismiss: () -> Void
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.themeTeal.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: "bag.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.themeTeal)
            }
            
            // Title
            Text("Selling Limit Reached")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.themePrimary)
            
            // Message
            Text("You've reached your monthly selling limit. Upgrade to Pro Seller for unlimited sales and more!")
                .font(.body)
                .foregroundColor(.themeSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Features
            VStack(alignment: .leading, spacing: 14) {
                FeatureRow(icon: "♾️", text: "Unlimited sales on Styleto Store")
                FeatureRow(icon: "📸", text: "Unlimited clothes detection")
                FeatureRow(icon: "✨", text: "Unlimited outfit suggestions")
            }
            .padding(.horizontal)
            
            // Buttons
            VStack(spacing: 12) {
                Button {
                    onUpgrade()
                } label: {
                    Text("Upgrade to Pro Seller")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.themeTeal)
                        .cornerRadius(16)
                }
                
                Button {
                    onDismiss()
                } label: {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.themeSecondary)
                }
            }
        }
        .padding(24)
        .background(Color.themeCard)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 32)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            Text(text)
                .font(.body)
                .foregroundColor(.themeText)
            Spacer()
        }
    }
}
