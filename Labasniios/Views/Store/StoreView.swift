//
//  StoreView.swift
//  Labasniios
//

import SwiftUI

struct StoreView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var viewModel = StoreViewModel()
    @ObservedObject private var cartManager = CartManager.shared
    @State private var searchText = ""
    @State private var showCart = false
    @State private var showChat = false
    @State private var showAddSheet = false
    
    // AJOUT : état pour savoir quel onglet est actif
    @State private var selectedTab: StoreTab = .myItems
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // Enum pour les deux onglets
    private enum StoreTab {
        case myItems, discover
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerWithTopButtons
                        searchBar
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // NOUVEAU : Le segment horizontal comme sur ta photo
                    tabSegment
                        .padding(.horizontal, 16)
                    // ✨ NOUVEAU : Carte de suggestion de vente
                    if viewModel.showSellSuggestion, let suggestion = viewModel.currentSuggestion {
                        SellSuggestionCard(
                            clothe: suggestion,
                            onAccept: {
                                print("✅ User wants to sell: \(suggestion.id)")
                                viewModel.acceptSellSuggestion()
                            },
                            onReject: {
                                print("❌ User rejected sell suggestion")
                                viewModel.rejectSellSuggestion()
                            }
                        )
                        .transition(
                            AnyTransition.move(edge: .top)
                                .combined(with: .opacity)
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.showSellSuggestion)
                    }
                    // Contenu qui change selon l'onglet sélectionné
                    if selectedTab == .myItems {
                        if !viewModel.storeItems.isEmpty {
                            myItemsGrid
                                .padding(.horizontal, 16)
                        } else {
                            // Message quand l'utilisateur n'a rien à vendre
                            VStack(spacing: 16) {
                                Image(systemName: "tshirt")
                                    .font(.system(size: 60))
                                    .foregroundColor(.themePrimary.opacity(0.3))
                                    .padding(.top, 60)
                                
                                Text("No items in your store yet")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.themeText)
                                
                                Text("Add clothes from your wardrobe to start selling")
                                    .font(.system(size: 15))
                                    .foregroundColor(.themeSecondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Button {
                                    print("🔘 [StoreView] Empty state button tapped")
                                    viewModel.loadMyClothes()
                                    showAddSheet = true
                                } label: {
                                    Text("Add your first item")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(Color.themePrimary)
                                        .clipShape(Capsule())
                                }
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                        }
                    } else {
                        if !viewModel.discoverItems.isEmpty {
                            discoverGrid
                                .padding(.horizontal, 16)
                        } else {
                            // Message quand il n'y a rien à découvrir
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 60))
                                    .foregroundColor(.themePrimary.opacity(0.3))
                                    .padding(.top, 60)
                                
                                Text("No items to discover")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.themeText)
                                
                                Text("Check back later for new items")
                                    .font(.system(size: 15))
                                    .foregroundColor(.themeSecondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                        }
                    }

                    Spacer(minLength: 120)
                }
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.loadMyStore()
                // ← SUPPRIME loadDiscoverStore(), c'est déjà appelé dans loadMyStore()
            }

            // Bouton + flottant (inchangé)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        print("🔘 [StoreView] Add button tapped")
                        print("📦 [StoreView] Loading clothes...")
                        viewModel.loadMyClothes()
                        
                        // Utiliser Task pour s'assurer que ça se passe sur le thread principal
                        Task { @MainActor in
                            print("🔄 [StoreView] Setting showAddSheet to true...")
                            showAddSheet = true
                            print("✅ [StoreView] showAddSheet is now: \(showAddSheet)")
                            
                            // Vérifier après un court délai
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                            print("🔍 [StoreView] After delay, showAddSheet is: \(showAddSheet)")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(Color.themePrimary)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 30)
                }
            }

            // Toast suppression (inchangé)
            if viewModel.showToast {
                VStack {
                    Text("Item deleted")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.red.opacity(0.9))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .transition(.move(edge: .top))
                        .animation(.spring(), value: viewModel.showToast)
                    Spacer()
                }
                .padding(.top, 100)
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddToStoreSheet(viewModel: viewModel)
                .onAppear {
                    print("📄 [StoreView] AddToStoreSheet appeared")
                }
                .onDisappear {
                    print("📄 [StoreView] AddToStoreSheet disappeared")
                    viewModel.showAddToStore = false
                }
        }
        .onChange(of: showAddSheet) { oldValue, newValue in
            print("🔄 [StoreView] showAddSheet changed: \(oldValue) -> \(newValue)")
            viewModel.showAddToStore = newValue
        }
        // ✨ NOUVEAU : Observer les changements de showAddToStore du ViewModel
        .onChange(of: viewModel.showAddToStore) { oldValue, newValue in
            print("🔄 [StoreView] viewModel.showAddToStore changed: \(oldValue) -> \(newValue)")
            if newValue != showAddSheet {
                showAddSheet = newValue
            }
        }
    }

    // MARK: - Segment horizontal
    private var tabSegment: some View {
        HStack(spacing: 0) {
            // Bouton "My Items"
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = .myItems
                }
            } label: {
                Text("My Items")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(selectedTab == .myItems ? .white : Color.themePrimary.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(selectedTab == .myItems ? Color.themePrimary : Color.clear)
                    )
            }
            
            // Bouton "Discover"
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = .discover
                }
            } label: {
                Text("Discover")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(selectedTab == .discover ? .white : Color.themePrimary.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(selectedTab == .discover ? Color.themePrimary : Color.clear)
                    )
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(Color.themePrimary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Header avec Chat + Panier
    private var headerWithTopButtons: some View {
        HStack {
            Text("Store")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.themePrimary)

            Spacer()

            HStack(spacing: 16) {
                Button {
                    showChat = true
                } label: {
                    Image(systemName: "message.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.themePrimary)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8)
                }
                .fullScreenCover(isPresented: $showChat) {
                    ChatView()
                }

                Button {
                    showCart = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        // Le bouton exactement comme avant
                        Image(systemName: "cart.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.themePrimary)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 8)
                        
                        // Le badge rouge – apparaît uniquement si > 0
                        if cartManager.itemCount > 0 {
                            Text("\(cartManager.itemCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 18, minHeight: 18)
                                .background(Color.red)
                                .clipShape(Circle())
                                .padding(4)
                                .transition(.scale.combined(with: .opacity))
                                .animation(.spring(response: 0.3), value: CartManager.shared.itemCount)
                        }
                    }
                }
                .fullScreenCover(isPresented: $showCart) {
                    CartView()
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.themeSecondary)

            TextField("Search for an item...", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .onChange(of: searchText) { newValue in
                    viewModel.searchText = newValue
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.themeSecondary.opacity(0.5), lineWidth: 2)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.themeSoftPink.opacity(0.25)))
        )
    }

    private var myItemsHeaderWithPlusButton: some View {
        HStack {
            Text("My Items")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.themeTeal)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var myItemsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.storeItems) { item in
                ProductCard(storeItem: item, viewModel: viewModel)
            }
        }
    }

    private var discoverGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.discoverItems) { item in
                ProductCard(storeItem: item, viewModel: nil)
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, items: [Store], @ViewBuilder content: () -> some View) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.themeTeal)
                content()
            }
        }
    }
}

// MARK: - ProductCard
private struct ProductCard: View {
    let storeItem: Store
    let viewModel: StoreViewModel?

    @State private var showEditPopup = false
    @State private var showDiscoverDetail = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(colors: [Color.themeSecondary.opacity(0.35), Color.themeAqua.opacity(0.45)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 160)

                AsyncImage(url: URL(string: storeItem.clothe?.imageURL ?? "")) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFit().frame(height: 140)
                            .opacity(storeItem.isAvailable ? 1.0 : 0.5)
                    } else {
                        Image(systemName: "photo")
                            .resizable().scaledToFit().frame(height: 140)
                            .foregroundColor(.gray)
                    }
                }

                // Tag condition en haut à droite (étiquette moderne)
                if let condition = storeItem.condition {
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(condition.color)
                                    .frame(width: 5, height: 5)
                                Text(condition.displayName)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(condition.color)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(condition.color.opacity(0.15))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(condition.color.opacity(0.4), lineWidth: 1)
                            )
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                }

                if !storeItem.isAvailable {
                    Text("SOLD")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .padding()
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(storeItem.clothe?.category ?? "Unknown")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.themeTeal)
                        .lineLimit(1)
                    
                    Text("\(storeItem.price, specifier: "%.2f") DT")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(storeItem.isAvailable ? .themePrimary : .gray)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.themeCard)
        }
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.themeCard))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 10)
        .opacity(storeItem.isAvailable ? 1.0 : 0.7)
        .onTapGesture {
            if viewModel != nil {
                showEditPopup = true
            } else {
                showDiscoverDetail = true
            }
        }
        .sheet(isPresented: $showEditPopup) {
            EditStorePopup(viewModel: viewModel!, storeItem: storeItem)
        }
        .sheet(isPresented: $showDiscoverDetail) {
            DiscoverItemDetailSheet(storeItem: storeItem)
        }
    }
}

#Preview {
    StoreView()
}
