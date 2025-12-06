//
//  VTOClothingSelector.swift
//  Labasniios
//
//  Created by Aziz on 6/12/2025.
//

import SwiftUI

struct VTOClothingSelector: View {
    let clothesByCategory: [String: [VTOClothe]]
    let selectedIds: Set<String>
    let onToggle: (VTOClothe) -> Void
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 15) {
                ForEach(Array(clothesByCategory.keys.sorted()), id: \.self) { category in
                    CategorySection(
                        title: category.capitalized,
                        clothes: clothesByCategory[category] ?? [],
                        selectedIds: selectedIds,
                        onToggle: onToggle
                    )
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let title: String
    let clothes: [VTOClothe]
    let selectedIds: Set<String>
    let onToggle: (VTOClothe) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundColor(.white)
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(clothes) { clothe in
                        VTOClothingThumbnail(
                            clothe: clothe,
                            isSelected: selectedIds.contains(clothe.id),
                            onTap: { onToggle(clothe) }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Thumbnail
struct VTOClothingThumbnail: View {
    let clothe: VTOClothe
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                AsyncImage(url: URL(string: clothe.vtoImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                .shadow(radius: isSelected ? 6 : 2)
                
                // Badge de statut
                if !clothe.isReadyForVTO {
                    Text(clothe.processingStatus.rawValue)
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
                
                Text(clothe.category.capitalized)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(width: 90)
        }
    }
}
