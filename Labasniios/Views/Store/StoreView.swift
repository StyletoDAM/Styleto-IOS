//
//  StoreView.swift
//  Labasniios
//
//  Created by MacBook on 2/11/2025.
//

import SwiftUI


struct StoreView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var viewModel = StoreViewModel()
    @State private var searchText = ""
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    searchBar

                    // MARK: - My Items
                    sectionHeader(title: "My Items", items: viewModel.storeItems) {
                        myItemsGrid
                    }

                    // MARK: - Discover
                    sectionHeader(title: "Discover", items: viewModel.discoverItems) {
                        discoverGrid
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.loadMyStore()
                //viewModel.loadDiscoverItems()  // ← Charge les deux
            }

            // Bouton flottant
            Button {
                viewModel.showAddToStore = true
                viewModel.loadMyClothes()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.themePrimary)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.20), radius: 8, x: 0, y: 4)
            }
            .padding(.bottom, 24)
            .padding(.trailing, 24)
            .overlay(
                    Group {
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
                        }
                    }
                )
        }
        .sheet(isPresented: $viewModel.showAddToStore) {
            AddToStoreSheet(viewModel: viewModel)
        }
    
    }

    // MARK: - Vues Internes
    private var header: some View {
        Text("Store")
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(.themePrimary)
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
            
            // Bouton X pour effacer
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
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.themeSoftPink.opacity(0.25))
                )
        )
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
    private var myItemsGrid: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
            ForEach(viewModel.storeItems) { item in
                ProductCard(storeItem: item, viewModel: viewModel)            }
        }
    }

    private var discoverGrid: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
            ForEach(viewModel.discoverItems) { item in
                ProductCard(storeItem: item, viewModel: nil)            }
        }
    }

    private var productGrid: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
            ForEach(viewModel.storeItems) { item in
                ProductCard(storeItem: item, viewModel: nil)                    .onTapGesture { }
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - ProductCard
private struct ProductCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let storeItem: Store
    let viewModel: StoreViewModel?
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var showEditPopup = false

    var body: some View {
        VStack(spacing: 0) {
            // Image
            ZStack {
                LinearGradient(
                    colors: [Color.themeSecondary.opacity(0.35), Color.themeAqua.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)

                AsyncImage(url: URL(string: storeItem.clothe?.imageURL ?? "")) { phase in
                    switch phase {
                    case .empty: ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFit().frame(height: 140)
                            .opacity(storeItem.isAvailable ? 1.0 : 0.5) // Griser si vendu
                    case .failure:
                        Image(systemName: "photo")
                            .resizable().scaledToFit().frame(height: 140)
                            .foregroundColor(.gray)
                    @unknown default: EmptyView()
                    }
                }
                
                // Badge "SOLD" si vendu
                if !storeItem.isAvailable {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("SOLD")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .shadow(radius: 4)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }

            // Info + Poubelle
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

                // Poubelle (seulement dans My Items)
                if viewModel != nil {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.themePrimary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.themePrimary.opacity(0.15))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .opacity(isDeleting ? 0.5 : 1.0)
                    .disabled(isDeleting)
                }
            }
            .padding(14)
            .background(Color.themeCard)
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.themeCard)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 10)
        .opacity(storeItem.isAvailable ? 1.0 : 0.7) // Transparence globale si vendu
        .alert("Delete this item?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .opacity(isDeleting ? 0.6 : 1.0)
        .animation(.easeInOut, value: isDeleting)
        .onTapGesture {
            if viewModel != nil {
                showEditPopup = true
            }
        }
        .sheet(isPresented: $showEditPopup) {
            EditStorePopup(viewModel: viewModel!, storeItem: storeItem)
        }
    }

    private func deleteItem() {
        guard let viewModel = viewModel else { return }
        isDeleting = true
        viewModel.deleteStoreItem(storeItem)
    }
}

#Preview {
    StoreView()
}
