import SwiftUI

struct OutfitsView: View {
    @StateObject private var viewModel = OutfitsViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showStylePopup = false
    @State private var selectedStyle: String?
    @State private var currentSuggestion: Outfit?


    @Environment(\.managedObjectContext) private var context


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    suggestionCard
                    VStack {
                        if let suggestion = viewModel.suggestion {
                            SuggestionCard(
                                outfit: suggestion,
                                onAccept: {
                                    withAnimation {
                                        viewModel.acceptSuggestion()
                                    }
                                },
                                onReject: {
                                    withAnimation {
                                        viewModel.rejectSuggestion()
                                    }
                                }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut, value: viewModel.suggestion != nil)

                    sectionHeader

                    if viewModel.isLoading && viewModel.outfits.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    } else if viewModel.outfits.isEmpty {
                        emptyState
                    } else {
                        tenueList
                    }

                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .sheet(isPresented: $showStylePopup) {
                StyleSelectionPopup(isPresented: $showStylePopup, selectedStyle: $selectedStyle)
                    .onDisappear {
                                if let style = selectedStyle {
                                    // Générer un outfit aléatoire selon le style choisi
                                    viewModel.generateSuggestion()
                                }
                            }
            }

            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: FavoritesView()) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.themePrimary)
                    }
                }
            }
            .onAppear {
                viewModel.loadOutfits()
            }
            .refreshable {
                viewModel.loadOutfits()
            }
        }
        
    }

    // MARK: - Header
    private var header: some View {
        Text("My Outfits")
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(.themePrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Suggestion Card
    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Suggestion")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Text("The weather is nice today! Why not try a light and colorful outfit?")
                .foregroundColor(.white.opacity(0.95))
            Button("See suggestion") {
                showStylePopup = true
            }
            .font(.system(size: 16, weight: .semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
            .foregroundColor(.themePrimary)
            .clipShape(Capsule())
        }
        .padding(20)
        .background(
            LinearGradient(colors: [.themeSecondary, .themePrimary],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 10)
        
    }
    
    

    // MARK: - Section Header
    private var sectionHeader: some View {
        Text("Recent Outfits")
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(.themeTeal)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tshirt")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No outfits at the moment")
                .font(.title3)
                .foregroundColor(.themeSecondaryText)
            Button("Generate an outfit") {
                viewModel.generateSuggestion()
            }
            .buttonStyle(.borderedProminent)
            .tint(.themeTeal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Tenue List
    private var tenueList: some View {
        VStack(spacing: 18) {
            ForEach(viewModel.outfits) { outfit in
                TenueCard(outfit: outfit)
            }
        }
    }

}

// MARK: - Tenue Card (mise à jour)
struct TenueCard: View {
    @State private var isFavorite: Bool = false
    @ObservedObject private var themeManager = ThemeManager.shared
    let outfit: Outfit
    var isSuggestion = false
    var onAccept: (() -> Void)?
    var onReject: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(outfit.title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.themeTeal)
                    Text("\(outfit.itemsCount) article\(outfit.itemsCount > 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundColor(.themeSecondaryText)
                }
                Spacer()
                Button {
                        isFavorite.toggle()
                    FavoritesService.shared.toggleFavorite(outfitId: outfit.id)
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isFavorite ? .themePrimary : .themeSecondary)
                            .padding(8)
                            .background(Color.themeCard.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .onAppear {
                        isFavorite = outfit.isLocallyFavorite
                    }
            }

            HStack(spacing: 14) {
                ForEach(outfit.previewClothes) { clothe in
                    AsyncImage(url: URL(string: clothe.imageURL)) { phase in
                        switch phase {
                        case .empty: placeholder
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        case .failure:
                            placeholder.overlay(
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                            )
                        @unknown default: placeholder
                        }
                    }
                }
                
                ForEach(0..<(3 - outfit.previewClothes.count), id: \.self) { _ in
                    placeholder.overlay(
                        Image(systemName: "plus")
                            .foregroundColor(.gray.opacity(0.6))
                    )
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(.themeTeal.opacity(0.7))
                Text(outfit.dateLabel)
                    .font(.subheadline)
                    .foregroundColor(.themeTeal.opacity(0.7))
            }

            // BOUTONS UNIQUEMENT SI SUGGESTION
            if isSuggestion {
                HStack(spacing: 12) {
                    Button("Reject") {
                        onReject?()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.9))
                    .clipShape(Capsule())

                    Button("Accept") {
                        onAccept?()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.9))
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(isSuggestion ? Color.themeCard.opacity(0.95) : Color.themeCard)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
        .animation(.easeInOut(duration: 0.3), value: isSuggestion)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.themeSoftPink.opacity(0.2))
            .frame(width: 56, height: 56)
    }
}

