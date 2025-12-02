import SwiftUI

struct SellSuggestionCard: View {
    let clothe: Clothe
    var onAccept: () -> Void
    var onReject: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header avec icône
            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sell Suggestion")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.themePrimary)
                    
                    Text("Not wearing this much?")
                        .font(.system(size: 13))
                        .foregroundColor(.themeSecondaryText)
                }
                
                Spacer()
            }
            
            // Message
            Text("You haven't worn this item much. Would you like to sell it in the store?")
                .font(.system(size: 15))
                .foregroundColor(.themeText)
                .lineSpacing(4)
            
            // Image du vêtement
            HStack {
                Spacer()
                
                AsyncImage(url: URL(string: clothe.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    case .failure:
                        placeholder.overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                        )
                    @unknown default:
                        placeholder
                    }
                }
                
                Spacer()
            }
            
            // Informations du vêtement
            VStack(alignment: .leading, spacing: 8) {
                infoRow(icon: "tshirt.fill", text: clothe.category ?? "Unknown")
                infoRow(icon: "paintpalette.fill", text: clothe.color ?? "Unknown")
                infoRow(icon: "star.fill", text: clothe.style ?? "Unknown")
                
                // Stats
                HStack(spacing: 16) {
                    statBadge(icon: "checkmark.circle.fill",
                             value: "\(clothe.acceptedCount ?? 0)",
                             color: .green)
                    statBadge(icon: "xmark.circle.fill",
                             value: "\(clothe.rejectedCount ?? 0)",
                             color: .red)
                }
            }
            .padding(.vertical, 8)
            
            // Boutons
            HStack(spacing: 12) {
                Button {
                    onReject()
                } label: {
                    Text("Not Now")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(14)
                }
                
                Button {
                    onAccept()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                        Text("Sell It")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.themePrimary, .themeSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 16)
    }
    
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.themeSoftPink.opacity(0.2))
            .frame(width: 120, height: 120)
            .overlay(
                ProgressView()
                    .tint(.themeTeal)
            )
    }
    
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.themeTeal)
                .frame(width: 16)
            
            Text(text.capitalized)
                .font(.system(size: 14))
                .foregroundColor(.themeText)
        }
    }
    
    private func statBadge(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.themeText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}
