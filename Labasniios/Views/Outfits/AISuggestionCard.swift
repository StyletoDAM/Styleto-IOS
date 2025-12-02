import SwiftUI
 
// MARK: - AISuggestionCard - Version ultra minimaliste
struct AISuggestionCard: View {
    let suggestion: AIRecommendationResponse
    let isAccepting: Bool
    var onAccept: () -> Void
    var onReject: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header avec icône AI - Plus compact
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Suggestion")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.themePrimary)
                    
                    // Info météo si disponible
                    if let city = suggestion.metadata.weather.city {
                        HStack(spacing: 4) {
                            Image(systemName: "cloud.sun.fill")
                                .font(.system(size: 10))
                            Text("\(Int(suggestion.metadata.weather.temperature))°C • \(city)")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.themeSecondaryText)
                    }
                }
                
                Spacer()
            }
            
            // Preview des 3 vêtements - Plus compact
            HStack(spacing: 12) {
                outfitItemView(clothe: suggestion.outfit.top, label: "Top")
                outfitItemView(clothe: suggestion.outfit.bottom, label: "Bottom")
                outfitItemView(clothe: suggestion.outfit.footwear, label: "Shoes")
            }
            
            // Explication AI - Plus fine
            if let explanation = suggestion.metadata.explanation {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        explanationBadge(
                            icon: "checkmark.circle.fill",
                            text: suggestion.metadata.preference.capitalized
                        )
                        explanationBadge(
                            icon: "thermometer.sun.fill",
                            text: suggestion.metadata.season.capitalized
                        )
                        if let totalScore = explanation.top.totalScore {
                            explanationBadge(
                                icon: "star.fill",
                                text: "\(Int(totalScore * 100))%"
                            )
                        }
                    }
                }
            }
            
            // ✅ Boutons fins style iOS natif
            HStack(spacing: 8) {
                Button {
                    if !isAccepting {
                        onReject()
                    }
                } label: {
                    Text("Reject")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(10)
                }
                .disabled(isAccepting)
                .opacity(isAccepting ? 0.4 : 1.0)
                
                Button {
                    if !isAccepting {
                        onAccept()
                    }
                } label: {
                    HStack(spacing: 4) {
                        if isAccepting {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.75)
                        }
                        Text(isAccepting ? "Saving..." : "Accept")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.themeTeal)
                    .cornerRadius(10)
                }
                .disabled(isAccepting)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
        .opacity(isAccepting ? 0.7 : 1.0)
    }
    
    // MARK: - Outfit Item View - Plus compact
    private func outfitItemView(clothe: Clothe, label: String) -> some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: clothe.imageURL)) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                case .failure:
                    placeholder.overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    )
                @unknown default:
                    placeholder
                }
            }
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.themeSecondaryText)
        }
    }
    
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.themeSoftPink.opacity(0.2))
            .frame(width: 80, height: 80)
            .overlay(
                ProgressView()
                    .tint(.themeTeal)
                    .scaleEffect(0.8)
            )
    }
    
    // MARK: - Explanation Badge - Style badges horizontaux
    private func explanationBadge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.themeTeal)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.themeSecondaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.themeSoftPink.opacity(0.15))
        .cornerRadius(8)
    }
}
