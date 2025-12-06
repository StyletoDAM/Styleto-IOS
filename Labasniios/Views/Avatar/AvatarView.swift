// Views/Avatar/AvatarView.swift
import SwiftUI

struct AvatarView: View {
    @StateObject private var vtoViewModel = VTOViewModel()
    
    var body: some View {
        ZStack {
            if vtoViewModel.isLoading {
                // Loading state
                VStack(spacing: 30) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.themePrimary)
                    
                    Text("Chargement de votre garde-robe...")
                        .font(.subheadline)
                        .foregroundColor(.themeSecondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.themeBackground.ignoresSafeArea())
            } else if let errorMessage = vtoViewModel.errorMessage {
                // Error state
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.themeSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Réessayer") {
                        Task {
                            await vtoViewModel.loadClothes()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.themeBackground.ignoresSafeArea())
            } else if vtoViewModel.clothesByCategory.isEmpty {
                // Empty state
                VStack(spacing: 30) {
                    Image(systemName: "tshirt")
                        .font(.system(size: 80))
                        .foregroundColor(.themePrimary.opacity(0.6))
                    
                    Text("Aucun vêtement prêt")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.themeTeal)
                    
                    Text("Ajoutez des vêtements dans votre garde-robe pour utiliser le Virtual Try-On")
                        .font(.subheadline)
                        .foregroundColor(.themeSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Aller à la garde-robe") {
                        // Navigation vers DressingView
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.themeBackground.ignoresSafeArea())
            } else {
                // VTO Active
                VTOCameraView(viewModel: vtoViewModel)
                    .ignoresSafeArea()
            }
        }
        .task {
            await vtoViewModel.loadClothes()
        }
    }
}

#Preview {
    AvatarView()
}
