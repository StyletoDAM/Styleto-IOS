
import SwiftUI

struct PackProfileCard: View {
    @State private var showPlans = false
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Card 1: Free Pack + Usage
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.themePrimary.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your current pack")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.themeSecondaryText)
                        
                        Text("Free Pack")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.themePrimary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.themeSecondaryText)
                }
                
                Text("Your usage this month")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.themeText.opacity(0.9))
                
                // Progress bars
                VStack(spacing: 12) {
                    ProgressRow(icon: "tshirt", title: "Clothing scans", current: 3, max: 5)
                    ProgressRow(icon: "wand.and.stars", title: "Outfit suggestions", current: 2, max: 3)
                    ProgressRow(icon: "bag", title: "Items for sale", current: 1, max: 3)
                }
            }
            .padding(20)
            .background(Color.themeCard)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            
            // MARK: - Card 2: Upgrade to Premium
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.upgrade.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                    
                    Text("Upgrade to Premium")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Unlock all AI features\nand create your personalized 3D avatar.")
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
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.themePrimary)
                    )
                }
                .sheet(isPresented: $showPlans) {
                    SubscriptionPlansView()
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.themePrimary.opacity(0.85),
                                Color.themePrimary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.themePrimary.opacity(0.4), radius: 15, x: 0, y: 8)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Progress Row
private struct ProgressRow: View {
    let icon: String
    let title: String
    let current: Int
    let max: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.themeTeal)
                .frame(width: 28)
            
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.themeText)
            
            Spacer()
            
            Text("\(current)/\(max)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.themePrimary)
        }
        
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.themeSoftPink.opacity(0.25))
                    .frame(height: 9)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.themeTeal)
                    .frame(width: geo.size.width * CGFloat(current)/CGFloat(max), height: 9)
            }
        }
        .frame(height: 9)
    }
}

#Preview {
    ScrollView {
        PackProfileCard()
            .padding(.top, 50)
            .background(Color.themeBackground)
    }
}
