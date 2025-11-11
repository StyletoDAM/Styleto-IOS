//
//  StoreView.swift
//  Labasniios
//
//  Created by MacBook on 2/11/2025.
//

import SwiftUI

struct StoreProduct: Identifiable {
    let id = UUID()
    let title: String
    let price: String
    let rating: Double
    let emoji: String

    static let samples: [StoreProduct] = [
        .init(title: "Pull tricoté", price: "45 DT", rating: 4.5, emoji: "🧶"),
        .init(title: "Jean slim", price: "65 DT", rating: 4.8, emoji: "👖"),
        .init(title: "Chemise", price: "59 DT", rating: 4.2, emoji: "👔"),
        .init(title: "Veste été", price: "120 DT", rating: 4.7, emoji: "🧥"),
        .init(title: "T-shirt coton", price: "35 DT", rating: 4.1, emoji: "👕"),
        .init(title: "Parka", price: "210 DT", rating: 4.9, emoji: "🧥")
    ]
}

struct StoreView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    private let products = StoreProduct.samples
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    header
                    Spacer()
                    floatingAddButton
                }
                searchBar
                sectionHeader
                productGrid
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color.themeSoftPink.opacity(0.25).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        Text("Store")
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(.themePrimary)
    }
    
    private var floatingAddButton: some View {
        Button {
            // Bouton statique pour le moment (aucune action)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.themePrimary)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
        }
        .accessibilityIdentifier("add-article-button")
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.themeSecondary)
            TextField("Rechercher un article...", text: .constant(""))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .disabled(true)
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

    private var sectionHeader: some View {
        Text("Articles populaires")
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(.themeTeal)
            .padding(.top, 4)
    }

    private var productGrid: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
            ForEach(products) { product in
                ProductCard(product: product)
            }
        }
        .padding(.top, 4)
    }
}

private struct ProductCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let product: StoreProduct

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [Color.themeSecondary.opacity(0.35), Color.themeAqua.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)

                Text(product.emoji)
                    .font(.system(size: 54))
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.themeTeal)
                        .lineLimit(1)
                    Text(product.price)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.themePrimary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", product.rating))
                        .foregroundColor(.themeSecondaryText)
                        .font(.system(size: 15, weight: .medium))
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
        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 10)
    }
}

#Preview {
    StoreView()
}

