//
//  PhotoGuidePopupView.swift
//  Labasniios
//
//  Created by Aziz on 22/11/2025.
//

// PhotoGuidePopupView.swift
import SwiftUI

struct PhotoGuidePopupView: View {
    @Binding var isShowing: Bool
    let onContinue: () -> Void
    
    @State private var currentTip = 0
    
    private let tips = [
        PhotoTip(
            icon: "light.max",
            title: "Good Lighting",
            description: "Use natural light or bright room lighting for best results",
            color: Color.yellow
        ),
        PhotoTip(
            icon: "rectangle.on.rectangle",
            title: "Plain Background",
            description: "Place the item on a solid color surface (white, grey, or any plain color)",
            color: Color.themeTeal
        ),
        PhotoTip(
            icon: "target",
            title: "Center the Item",
            description: "Make sure the clothing item fills most of the frame",
            color: Color.themePrimary
        ),
        PhotoTip(
            icon: "hand.raised.fill",
            title: "Flat & Smooth",
            description: "Lay the item flat and smooth out wrinkles for accurate detection",
            color: Color.themeAqua
        )
    ]
    
    var body: some View {
        ZStack {
            // Fond semi-transparent
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.themePrimary)
                    
                    Text("Photo Tips")
                        .font(.title2.bold())
                        .foregroundColor(.themePrimary)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            isShowing = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // Carousel de tips
                TabView(selection: $currentTip) {
                    ForEach(0..<tips.count, id: \.self) { index in
                        TipCard(tip: tips[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 280)
                .padding(.horizontal, 20)
                
                // Indicateurs
                HStack(spacing: 8) {
                    ForEach(0..<tips.count, id: \.self) { index in
                        Circle()
                            .fill(currentTip == index ? Color.themePrimary : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentTip)
                    }
                }
                .padding(.top, 12)
                
                // Bouton Continue
                Button {
                    // Appeler onContinue (qui vérifiera le quota et fermera si nécessaire)
                    onContinue()
                } label: {
                    HStack(spacing: 8) {
                        Text("Got it!")
                        Image(systemName: "arrow.right")
                    }
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.themePrimary, Color.themeTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.themeBackground)
                    .shadow(color: .black.opacity(0.2), radius: 20)
            )
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

// MARK: - Tip Card
private struct TipCard: View {
    let tip: PhotoTip
    
    var body: some View {
        VStack(spacing: 20) {
            // Icône
            ZStack {
                Circle()
                    .fill(tip.color.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: tip.icon)
                    .font(.system(size: 42))
                    .foregroundColor(tip.color)
            }
            
            // Titre
            Text(tip.title)
                .font(.title3.bold())
                .foregroundColor(.themePrimary)
                .multilineTextAlignment(.center)
            
            // Description
            Text(tip.description)
                .font(.body)
                .foregroundColor(.themeSecondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(tip.color.opacity(0.08))
        )
    }
}

// MARK: - Model
struct PhotoTip {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Preview
struct PhotoGuidePopupView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoGuidePopupView(
            isShowing: .constant(true),
            onContinue: {
                print("Continue tapped")
            }
        )
    }
}
