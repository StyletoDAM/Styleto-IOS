// ClothingDetailSheet.swift
import SwiftUI

struct ClothingDetailSheet: View {
    let clothe: Clothe
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var viewModel: DressingViewModel
    
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    
    init(clothe: Clothe, viewModel: DressingViewModel) {
        self.clothe = clothe
        self.viewModel = viewModel
    }
    
    private func deleteClothe() {
        isDeleting = true
        
        viewModel.deleteClothe(clothe) { success in
            DispatchQueue.main.async {
                if success {
                    withAnimation {
                        dismiss()
                    }
                    
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                } else {
                    isDeleting = false
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Image Section
                Section {
                    VStack(spacing: 16) {
                        // Image du vêtement (SANS BACKGROUND)
                        AsyncImage(url: URL(string: clothe.imageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.05), Color.gray.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(20)
                                    
                            case .failure:
                                Rectangle()
                                    .fill(Color.themeSoftPink.opacity(0.3))
                                    .frame(height: 300)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .font(.largeTitle)
                                                .foregroundColor(.themeTeal.opacity(0.6))
                                            Text("Image unavailable")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    )
                                    .cornerRadius(20)
                                    
                            case .empty:
                                Rectangle()
                                    .fill(Color.themeSoftPink.opacity(0.3))
                                    .frame(height: 300)
                                    .overlay(
                                        ProgressView()
                                            .tint(.themePrimary)
                                    )
                                    .cornerRadius(20)
                                    
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // Badge AI
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                            Text("AI Analyzed")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.themePrimary.opacity(0.9))
                        )
                        .shadow(color: .themePrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                
                // MARK: - Clothing Information
                Section(header: Text("Details").font(.headline).foregroundColor(.themePrimary)) {
                    // Category
                    HStack {
                        Label("Type", systemImage: "tag.fill")
                            .font(.subheadline)
                            .foregroundColor(.themeTeal)
                        Spacer()
                        Text(clothe.category?.capitalized ?? "Unknown")
                            .font(.subheadline.bold())
                            .foregroundColor(.themePrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.themePrimary.opacity(0.15))
                            )
                    }
                    
                    // Color
                    if let color = clothe.color {
                        HStack {
                            Label("Color", systemImage: "paintpalette.fill")
                                .font(.subheadline)
                                .foregroundColor(.themeTeal)
                            Spacer()
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(hex: color) ?? .gray)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                Text(color.uppercased())
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Style
                    if let style = clothe.style {
                        HStack {
                            Label("Style", systemImage: "star.fill")
                                .font(.subheadline)
                                .foregroundColor(.themeTeal)
                            Spacer()
                            Text(style.capitalized)
                                .font(.subheadline.bold())
                                .foregroundColor(.themeTeal)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.themeTeal.opacity(0.15))
                                )
                        }
                    }
                    
                    // Season
                    if let season = clothe.season {
                        HStack {
                            Label("Season", systemImage: seasonIcon(for: season))
                                .font(.subheadline)
                                .foregroundColor(.themeTeal)
                            Spacer()
                            Text(season.capitalized)
                                .font(.subheadline.bold())
                                .foregroundColor(.themeAqua)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.themeAqua.opacity(0.15))
                                )
                        }
                    }
                }
                .listRowBackground(Color.themeCard)
                
                // MARK: - Owner Info (Optional)
                if let userInfo = clothe.userIdAsUser {
                    Section(header: Text("Owner").font(.headline).foregroundColor(.themePrimary)) {
                        HStack(spacing: 12) {
                            // Avatar
                            if let profilePicture = userInfo.profilePicture, let url = URL(string: profilePicture) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Circle()
                                        .fill(Color.themePrimary.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.white)
                                        )
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.themePrimary.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(userInfo.fullName ?? "Unknown User")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.themePrimary)
                                
                                if let email = userInfo.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.themeCard)
                }
                
                // MARK: - Delete Button
                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            if isDeleting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Label("Delete Item", systemImage: "trash.fill")
                                    .font(.subheadline.bold())
                            }
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .cornerRadius(12)
                        )
                    }
                    .disabled(isDeleting)
                    .listRowBackground(Color.clear)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .background(
                Color.themeSoftPink.opacity(UITraitCollection.current.userInterfaceStyle == .dark ? 0.1 : 0.25)
                    .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.themePrimary)
                    .font(.subheadline.bold())
                }
            }
            .alert("Delete this item?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteClothe()
                }
            } message: {
                Text("This action cannot be undone. The item will be permanently removed from your wardrobe.")
            }
        }
    }
    
    // MARK: - Helper Functions
    private func seasonIcon(for season: String) -> String {
        switch season.lowercased() {
        case "summer": return "sun.max.fill"
        case "winter": return "snowflake"
        case "fall", "autumn": return "leaf.fill"
        case "spring": return "cloud.sun.fill"
        default: return "calendar"
        }
    }
}

// MARK: - Preview
struct ClothingDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview available in runtime")
    }
}
