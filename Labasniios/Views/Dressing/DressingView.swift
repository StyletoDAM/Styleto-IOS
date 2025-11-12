//
//  DressingView.swift
//  Labasniios
//
//  Created by MacBook on 2/11/2025.
//

import SwiftUI

private struct ClothingItem: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let fillColor: Color
    let emoji: String

    static let samples: [ClothingItem] = [
        .init(title: "T-shirt blanc", category: "Hauts", fillColor: .white, emoji: "👕"),
        .init(title: "Jean bleu", category: "Bas", fillColor: Color(hex: "#4D5F8F"), emoji: "👖"),
        .init(title: "Robe rose", category: "Robes", fillColor: .db6a8f, emoji: "👗"),
        .init(title: "Baskets", category: "Chaussures", fillColor: Color(.darkGray), emoji: "👟"),
        .init(title: "Chemise", category: "Hauts", fillColor: .a7e0e0, emoji: "👔"),
        .init(title: "Short", category: "Bas", fillColor: .e8aabe, emoji: "🩳")
    ]
}

struct DressingView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    private let clothes = ClothingItem.samples
    private let categories = ["All", "Tops", "Bottoms", "Dresses", "Shoes", "Accessories"]
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                searchAndFilter
                categoryChips
                clothesGrid
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 80) // Espace pour le bouton flottant
        }
        .background(Color.themeSoftPink.opacity(0.18).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer() // Pousse le bouton à droite
                floatingAddButton
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
            }
            .background(Color.clear) // Transparent pour éviter le fond blanc
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("My Dressing")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.themePrimary)
            Spacer()
        }
        .padding(.top, 8)
    }

    private var searchAndFilter: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.themeSecondary)
                TextField("Search...", text: .constant(""))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .disabled(true)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.themeSecondary.opacity(0.6), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.themeSoftPink.opacity(0.25))
                    )
            )

            Circle()
                .fill(Color.themeAqua)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    CategoryChip(label: category, selected: index == 0)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var clothesGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(clothes) { item in
                ClothingCard(item: item)
            }
        }
        .padding(.bottom, 22)
    }

    private var floatingAddButton: some View {
        Button(action: {}) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(
                    Circle()
                        .fill(Color.themePrimary)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
                )
        }
        .padding(.trailing, 16)
        .padding(.top, 20)
        .accessibilityIdentifier("add-clothing-button")
    }
}

private struct CategoryChip: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let label: String
    let selected: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(selected ? .white : Color.themeTeal)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(selected ? Color.themePrimary : Color.themeSoftPink.opacity(0.6))
            )
    }
}

private struct ClothingCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let item: ClothingItem

    var body: some View {
        VStack(spacing: 0) {
            // Partie supérieure avec fond coloré et emoji centré
            ZStack {
                item.fillColor
                Text(item.emoji)
                    .font(.system(size: 50))
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            
            // Partie inférieure avec texte aligné à gauche
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.themeTeal)
                Text(item.category)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.themeTeal.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(item.fillColor)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    DressingView()
}

