import SwiftUI
import AVFoundation

struct CameraOverlayView: View {
    @ObservedObject var viewModel: AvatarViewModel
    @State private var selectedClothe: Clothe?
    
    private let columns: [GridItem] = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            // Caméra en arrière-plan
            CameraPreview(session: viewModel.cameraSession)
                .ignoresSafeArea()
            
            // Overlay : vêtements scrollables
            VStack {
                Spacer()
                
                // Scroll horizontal des vêtements
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.clothes) { clothe in
                            ClothingThumb(clothe: clothe, isSelected: selectedClothe?.id == clothe.id)
                                .onTapGesture {
                                    selectedClothe = clothe
                                    viewModel.selectedClothe = clothe
                                    print("Vêtement sélectionné : \(clothe.category ?? "")")
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 120)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            // Bouton fermer
            VStack {
                HStack {
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
                }
                .padding(.top, 50)
                .padding(.leading, 20)
                
                Spacer()
            }
        }
    }
}

// Miniature de vêtement
struct ClothingThumb: View {
    let clothe: Clothe
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: clothe.imageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(ProgressView().tint(.white))
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
