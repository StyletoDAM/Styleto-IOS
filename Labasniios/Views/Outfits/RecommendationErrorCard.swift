import SwiftUI

// MARK: - RecommendationErrorCard - Style similaire à AISuggestionCard
struct RecommendationErrorCard: View {
    let message: String
    var onDismiss: () -> Void
    var onNavigateToStore: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header avec icône et bouton fermer
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                    .foregroundColor(.themePrimary)
                
                Text("Outfit Recommendation")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.themePrimary)
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            
            // Message d'erreur (formaté de manière concise)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.themeSecondaryText)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Bouton pour naviguer vers le store
            Button {
                onDismiss()
                onNavigateToStore()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Go to Store")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.themeSecondary, .themePrimary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(50)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
    }
}

