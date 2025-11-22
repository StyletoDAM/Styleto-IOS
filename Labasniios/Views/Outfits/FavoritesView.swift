import SwiftUI

struct FavoritesView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = OutfitsViewModel()
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    
    @State private var outfitsLoaded = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    
                    if !outfitsLoaded {
                        ProgressView("Loading favorites...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if favoritesManager.favoriteOutfits.isEmpty {
                        emptyState
                    } else if filteredFavorites.isEmpty {
                        Text("No outfit found")
                            .foregroundColor(.red)
                    } else {
                        favoritesList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadOutfitsAndFavorites()
            }
            .refreshable {
                loadOutfitsAndFavorites()
            }
        }
    }
    
    private func loadOutfitsAndFavorites() {
        favoritesManager.fetchFavorites()
        viewModel.loadOutfits()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            outfitsLoaded = true
        }
    }
    
    private var filteredFavorites: [Outfit] {
        favoritesManager.favoriteOutfits.compactMap { favorite in
            viewModel.outfits.first { $0.id == favorite.outfitId }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        Text("My Favorites")
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(.themePrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No favorite outfits")
                .font(.title3)
                .foregroundColor(.themeSecondaryText)
            Text("Tap the heart in \"My Outfits\" to add them here")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
    
    // MARK: - Favorites List
    private var favoritesList: some View {
        VStack(spacing: 18) {
            ForEach(filteredFavorites) { outfit in
                TenueCard(outfit: outfit)
                    .padding(.horizontal, 4)
            }
        }
    }
}
