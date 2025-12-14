// CameraOverlayView.swift - VERSION AMÉLIORÉE avec Badge Experimental
import SwiftUI
import AVFoundation

struct CameraOverlayView: View {
    @ObservedObject var viewModel: AvatarViewModel
    @State private var selectedClothe: Clothe?
    @State private var showDebugInfo = false
    @State private var pulseAnimation = false  // ✨ Animation pour le badge
    
    private let columns: [GridItem] = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            // Afficher l'image traitée OU la caméra brute
            if let processed = viewModel.processedImage {
                Image(uiImage: processed)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            } else {
                CameraPreview(session: viewModel.cameraSession)
                    .ignoresSafeArea()
            }
            
            // ✨ NOUVEAU : Badge Experimental en haut au centre
            VStack {
                experimentalBadge
                    .padding(.top, 60)
                
                Spacer()
            }
            
            // Indicateur de traitement
            if viewModel.isProcessing {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("Processing...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .padding(.trailing, 20)
                        .padding(.top, 120)
                    }
                    Spacer()
                }
            }
            
            // Affichage erreur
            if let error = viewModel.errorMessage {
                VStack {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.top, 120)
                    Spacer()
                }
            }
            
            // Debug info (optionnel)
            if showDebugInfo {
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Clothes: \(viewModel.clothes.count)")
                            Text("Selected: \(selectedClothe?.category ?? "None")")
                            Text("Processed: \(viewModel.processedImage != nil ? "Yes" : "No")")
                        }
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(6)
                        .padding(20)
                    }
                    Spacer()
                }
            }
            
            // Barre de vêtements en bas
            VStack {
                Spacer()
                
                if !viewModel.clothes.isEmpty {
                    VStack(spacing: 12) {
                        // Instructions
                        Text("Step back 1.5m and select a clothing item")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(viewModel.clothes) { clothe in
                                    ClothingThumb(
                                        clothe: clothe,
                                        isSelected: selectedClothe?.id == clothe.id
                                    )
                                    .onTapGesture {
                                        selectedClothe = clothe
                                        viewModel.selectedClothe = clothe
                                        print("👕 Clothing selected: \(clothe.category ?? "unknown")")
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .frame(height: 120)
                    }
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                } else {
                    Text("No clothing available")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.bottom, 40)
                }
            }
            
            // Boutons en haut
            VStack {
                HStack {
                    // Bouton fermer
                    Button {
                        viewModel.stopCamera()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Bouton debug (optionnel)
                    Button {
                        showDebugInfo.toggle()
                    } label: {
                        Image(systemName: showDebugInfo ? "info.circle.fill" : "info.circle")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            // Démarrer l'animation pulse
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                pulseAnimation = true
            }
        }
    }
    
    // ✨ NOUVEAU : Badge Experimental élégant et discret
    private var experimentalBadge: some View {
        HStack(spacing: 8) {
            // Icône animée
            Image(systemName: "flask.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .opacity(pulseAnimation ? 0.6 : 1.0)
            
            // Texte
            Text("EXPERIMENTAL")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(.white)
            
            // Petit badge "Beta"
            Text("BETA")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.themePrimary.opacity(0.8))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            // Fond avec glassmorphism
            ZStack {
                // Backdrop blur simulé
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.4))
                
                // Bordure lumineuse
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.themePrimary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct ClothingThumb: View {
    let clothe: Clothe
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: clothe.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.white)
                        )
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(ProgressView().tint(.white))
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.themePrimary : Color.clear, lineWidth: 3)
            )
            .shadow(radius: isSelected ? 6 : 2)
            
            Text(clothe.category?.capitalized ?? "")
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 90)
    }
}
