import SwiftUI
 
struct OutfitsView: View {
    @StateObject private var viewModel = OutfitsViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showStylePopup = false
    @Environment(\.managedObjectContext) private var context
 
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        suggestionPromptCard
                        
                        // ✅ CARTE AI SUGGESTION (si disponible)
                        if let aiSuggestion = viewModel.aiSuggestion {
                            AISuggestionCard(
                                suggestion: aiSuggestion,
                                isAccepting: viewModel.isAccepting,  // ✅ NOUVEAU
                                onAccept: {
                                    print("👆 Bouton Accept pressé")
                                    viewModel.acceptAISuggestion()
                                },
                                onReject: {
                                    print("👆 Bouton Reject pressé")
                                    viewModel.rejectAISuggestion()
                                }
                            )
                            .transition(
                                AnyTransition.move(edge: .top)
                                    .combined(with: .opacity)
                            )
                        }
                        
                        sectionHeader
                        
                        if viewModel.isLoading && viewModel.outfits.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if let error = viewModel.errorMessage {
                            errorView(error)
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
                
                // ✅ Overlay de chargement pour la génération AI
                if viewModel.isGenerating {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                
                                Text("AI is creating your perfect outfit...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .padding(32)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.themePrimary.opacity(0.95))
                            )
                        )
                        .transition(.opacity)
                }
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .sheet(isPresented: $showStylePopup) {
                StyleSelectionPopup(
                    isPresented: $showStylePopup,
                    onStyleSelected: { style in
                        print("🎨 Style sélectionné:", style)
                        viewModel.generateAISuggestion(style: style)
                    }
                )
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
            .animation(.easeInOut(duration: 0.3), value: viewModel.aiSuggestion != nil)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isGenerating)
        }
    }
 
    // MARK: - Header
    private var header: some View {
        Text("My Outfits")
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(.themePrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
 
    // MARK: - Suggestion Prompt Card
    private var suggestionPromptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's AI Suggestion")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text("Let our AI create the perfect outfit based on weather and your style!")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.95))
            
            Button {
                showStylePopup = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Get AI Suggestion")
                }
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
                .foregroundColor(.themePrimary)
                .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.themeSecondary, .themePrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
 
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.body)
                .foregroundColor(.themeSecondaryText)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                viewModel.loadOutfits()
            }
            .buttonStyle(.borderedProminent)
            .tint(.themeTeal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
 
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tshirt")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No outfits yet")
                .font(.title3)
                .foregroundColor(.themeSecondaryText)
            
            Text("Try generating your first AI-powered outfit!")
                .font(.subheadline)
                .foregroundColor(.themeSecondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button {
                showStylePopup = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Generate Outfit")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.themeTeal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .padding(.horizontal, 32)
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

// MARK: - Tenue Card
struct TenueCard: View {
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let outfit: Outfit
 
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
                    FavoritesManager.shared.toggleFavorite(outfitId: outfit.id)
                } label: {
                    Image(systemName: favoritesManager.isFavorite(outfitId: outfit.id) ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(favoritesManager.isFavorite(outfitId: outfit.id) ? .themePrimary : .themeSecondary)
                        .padding(8)
                        .background(Color.themeCard.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 2)
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
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.themeCard)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
    }
 
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.themeSoftPink.opacity(0.2))
            .frame(width: 56, height: 56)
    }
}
