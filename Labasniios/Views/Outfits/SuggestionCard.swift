import SwiftUI

struct SuggestionCard: View {
    let outfit: Outfit
    var onAccept: () -> Void
    var onReject: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Style Suggestion")
                .font(.title2.bold())
                .foregroundColor(.themePrimary)
            
            // Preview des 3 vêtements aléatoires
            HStack(spacing: 12) {
                ForEach(outfit.previewClothes) { clothe in
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
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button("Reject") {
                    onReject()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.85))
                .clipShape(Capsule())
                
                Button("Accept") {
                    onAccept()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.85))
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.themeCard)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
    }
    
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.themeSoftPink.opacity(0.2))
            .frame(width: 80, height: 80)
    }
}
