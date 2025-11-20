//
//  StoreView.swift
//  Labasniios
//

import SwiftUI

struct StoreView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var viewModel = StoreViewModel()
    @State private var searchText = ""
    @State private var showCart = false
    @State private var showChat = false
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

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

                    if !viewModel.storeItems.isEmpty {
                        myItemsHeaderWithPlusButton
                            .padding(.horizontal, 16)
                    }

                    if !viewModel.storeItems.isEmpty {
                        myItemsGrid
                            .padding(.horizontal, 16)
                    }

                    if !viewModel.discoverItems.isEmpty {
                        sectionHeader(title: "Discover", items: viewModel.discoverItems) {
                            discoverGrid
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
            }

            // Bouton + flottant "+"
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        viewModel.showAddToStore = true
                        viewModel.loadMyClothes()
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

            // Toast suppression
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
        .sheet(isPresented: $viewModel.showAddToStore) {
            AddToStoreSheet(viewModel: viewModel)
        }
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
                    Image(systemName: "cart.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.themePrimary)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8)
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

// MARK: - ProductCard CORRIGÉE (la ligne qui posait problème est maintenant OK)
private struct ProductCard: View {
    let storeItem: Store
    let viewModel: StoreViewModel?

    @State private var showEditPopup = false
    @State private var showDiscoverDetail = false   // AJOUTÉ ICI !

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
                showDiscoverDetail = true  // Maintenant reconnu !
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
